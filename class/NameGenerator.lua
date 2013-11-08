-- Qi Daozei
-- Copyright (C) 2013 Josh Kelley
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

require "engine.class"
require "engine.NameGenerator"

module(..., package.seeall, class.inherit(engine.NameGenerator))

function _M:init(lang_def)
    engine.NameGenerator.init(self, lang_def)
end

-- Chinese surnames, taken from http://en.wikipedia.org/wiki/List_of_common_Chinese_surnames
-- and used under the terms of the Creative Commons Attribution-ShareAlike License.
_M.chinese_surnames = "Wang, Li, Zhang, Liu, Chen, Yang, Huang, Zhao, Wu, Zhou, Xu, Sun, Ma, Zhu, Hu, Guo, He, Gao, Lin, Luo, Zheng, Liang, Xie, Song, Tang, Xu, Han, Feng, Deng, Cao, Peng, Zeng, Xiao, Tian, Dong, Yuan, Pan, Yu, Jiang, Cai, Yu, Du, Ye, Cheng, Su, Wei, Lu, Ding, Ren, Shen, Yao, Yu, Jiang, Cui, Zhong, Tan, Lu, Wang, Fan, Jin, Shi, Liao, Jia, Xia, Wei, Fu, Fang, Bai, Zou, Meng, Xiong, Qin, Qui, Jiang, Yin, Xue, Yan, Duan, Lei, Hou, Long, Shi, Tao, Li, He, Gu, Mao, Hao, Gong, Shao, Wan, Qian, Yan, Tan, Wu, Dai, Mo, Kong, Xiang, Tang, Kang, Yi, Chang, Qiao, Lai, Wen"

-- Chinese given names, taken from http://en.wikipedia.org/wiki/Chinese_given_name
-- and used under the terms of the Creative Commons Attribution-ShareAlike License.
-- Male / female divisions are based on comments in Wikipedia and various other online resources.
_M.chinese_given_names_male = "Wei, Qiang, Lei, Jun, Yong, Jie, Tao, Ming, Chao, Ping, Gang"
_M.chinese_given_names_female = "Fang, Xiuying, Min, Jing, Li, Yang, Juan, Yan, Xiulan, Xia, Guiying, Na"

_M.chinese_name_male_def = {
    syllablesStart = _M.chinese_surnames,
    syllablesEnd = _M.chinese_given_names_male,
    rules = "$s $e",
}

_M.chinese_name_female_def = {
    syllablesStart = _M.chinese_surnames,
    syllablesEnd = _M.chinese_given_names_female,
    rules = "$s $e",
}

