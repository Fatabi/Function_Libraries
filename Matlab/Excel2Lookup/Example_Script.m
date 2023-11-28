clc
clear all
close all

addpath(genpath(cd))


f16RCS = Excel2Lookup("F16_RCS_HT0_A0_R0.csv");
f16RCS.ValidateData();