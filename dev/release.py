#!/usr/bin/python

# Python 2 compatibility
from __future__ import print_function

import codecs
from glob import glob
from hashlib import md5
import os
from os.path import abspath, dirname, exists, join, normpath
import re
import sys
from zipfile import ZipFile

if len(sys.argv) > 1:
    base_dir = sys.argv[1]
    init_lua_filename = join(base_dir, 'init.lua')
    if not exists(init_lua_filename):
        print("%s does not look like a module directory" % base_dir, file=sys.stderr)
        print("(%s does not exist)" % init_lua_filename, file=sys.stderr)
        sys.exit(2)
else:
    # Look for the base path to the module.  Assume that the script is in the
    # module directory or is immediately under the module directory.
    try_base_dir = [ abspath(dirname(sys.argv[0])) ]
    try_base_dir.append(normpath(join(try_base_dir[0], '..')))
    for d in try_base_dir:
        init_lua_filename = join(d, 'init.lua')
        if exists(init_lua_filename):
            base_dir = d
            break
    else:
        print("Unable to find module directory. Tried these locations:", file=sys.stderr)
        print("\n".join(try_base_dir), file=sys.stderr)
        sys.exit(2)

def parse_init_lua(init_lua_filename):
    """
    Parses init.lua.  Our "parser" is extremely primitive.  Fortunately, the
    parts of init.lua that we care about are very simple.
    """
    init = {}
    with codecs.open(init_lua_filename, 'r', "utf-8") as init_lua_file:
        for line in init_lua_file:
            try:
                m = re.search(r'^(\w+)\s*=\s*"(.*)"', line)
                if m:
                    key, value = m.groups()
                    init[m.group(1)] = m.group(2)
                    continue

                m = re.search(r'^(\w+)\s*=\s*\{\s*(.*?)\s*\}', line)
                if m:
                    key, value = m.groups()
                    entries = []
                    if value:
                        for e in re.split(r'\s*,\s*', value):
                            if e.startswith('"'):
                                entries.append(e.replace('"', ''))
                            else:
                                entries.append(int(e))
                    init[key] = entries
            except Exception as e:
                print("Failed to parse")
                print(line)
                print(e)
                return {}
                sys.exit(2)
    return init

def write_team(mod_base_dir, team_filename):
    """
    Writes the .team file for the module given in mod_base_dir.
    
    Note: Changes the current directory.
    """

    error_to_catch = getattr(__builtins__, 'FileNotFoundError', OSError)

    try:
        os.remove(team_filename)
    except error_to_catch:
        pass

    team_file = ZipFile(team_filename, 'w')

    old_cwd = os.getcwd()
    os.chdir(mod_base_dir)

    for root, dirs, files in os.walk('data'):
        for f in files:
            team_file.write(join(root, f))

    for f in glob('*.lua'):
        team_file.write(f, join('mod', f))

    for mod_dir in ['ai', 'class', 'dialogs']:
        if not exists(mod_dir):
            continue
        for root, dirs, files in os.walk(mod_dir):
            for f in files:
                team_file.write(join(root, f), join('mod', root, f))

    team_file.close()
    os.chdir(old_cwd)

def get_module_md5s(mod_filename):
    """
    Gets MD5 checksums for the .lua files in a .team or .teae file.
    """
    mod_file = ZipFile(mod_filename, 'r')
    md5s = []
    for file_info in mod_file.infolist():
        if file_info.filename.endswith('.lua'):
            with mod_file.open(file_info) as f:
                h = md5()
                h.update(f.read(10485760))
                md5s.append('/' + file_info.filename + ':' + h.hexdigest())
    return md5s

init = parse_init_lua(init_lua_filename)

team_filename = join(base_dir,
    '%s-%s.team' % (init["short_name"], ".".join([str(i) for i in init["version"]])))
engine_filename = normpath(join(base_dir, '..', '..', 'engines',
    '%s-%s.teae' % (init["engine"][3], ".".join([str(i) for i in init["engine"][:3]]))))
if not exists(engine_filename):
    print("Unable to find engine at %s" % engine_filename, file=sys.stderr)
    sys.exit(1)

print("Writing %s..." % team_filename)
write_team(base_dir, team_filename)
print("Done.")

print("Calculating MD5 sum...")
md5s = []
md5s.extend(get_module_md5s(team_filename))
md5s.extend(get_module_md5s(engine_filename))

h = md5()
h.update("".join(sorted(md5s)).encode('utf-8'))
print(h.hexdigest())

