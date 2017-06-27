%% Copyright (C) Naiyan Wang and Jingdong Wang and Dit-Yan Yeung.
%% "Online Robust Non-negative Dictionary Learning for Visual Tracking", ICCV2013
%% If you find any problems, please contact winsty@gmail.com

addpath('./affineUtility');
addpath('./computeUtility');
addpath('./imageUtility');
addpath('./drawUtility');
addpath(genpath('./SLEP_package_4.1/'));
trackparam;

% initialize variables
rand('state',0);  randn('state',0);
frame = double(data(:,:,1))/256;

tmpl.mean = warpimg(frame, param0, opt.tmplsize);
tmpl.mean = tmpl.mean / norm(tmpl.mean);  
tmpl.basis = [];


% p = [px, py, sx, sy, theta]; The location of the target in the first
% frame.
% px and py are th coordinates of the centre of the box
% sx and sy are the size of the box in the x (width) and y (height)
%   dimensions, before rotation
% theta is the rotation angle of the box
% paramOld = [p(1), p(2), p(3)/opt.tmplsize(2), p(5), p(4) /p(3) / (opt.tmplsize(1) / opt.tmplsize(2)), 0];
% (x, y, scale, th, aspect, skew)

% Sample positive templates
for i = 1 : opt.maxbasis / 10 
    tmpl.basis(:, (i - 1) * 10 + 1 : i * 10) = samplePos(frame, param0, opt.tmplsize);
end


% Sample negative templates
p0 = paramOld(5);
tmpl.basis(:, opt.maxbasis + 1 : opt.negativeBasis + opt.maxbasis) = sampleNeg(frame, param0, opt.tmplsize, opt.negativeBasis);

tmpl.numsample = 0; 
tmpl.reseig = 0;
sz = size(tmpl.mean);  N = sz(1)*sz(2);

param = [];
param.est = param0;
param.wimg = tmpl.mean;
param.negativeTmpl =[];
savedRes = [];
 
% draw initial track window
drawopt = drawtrackresult([], 0, frame, tmpl, param, []);
disp('resize the window as necessary, then press any key..'); pause;
drawopt.showcondens = 0;  drawopt.thcondens = 1/opt.numsample;

wimgs = [];

duration = 0; tic;
% Initialize sufficient statistics for online update.
A = cell(prod(opt.tmplsize), 1);      % A is (20*20)*number of pixels
B = cell(prod(opt.tmplsize), 1);      % B is (20*1)*number of pixels
for i = 1 : prod(opt.tmplsize)
    A{i} = zeros(opt.maxbasis, opt.maxbasis);
    B{i} = zeros(opt.maxbasis, 1);
end

% Parameters for feature selection.
paramSR.lambda2 = 0;
paramSR.mode = 2;

%selected features
posOri = selectFeature(tmpl.basis(:, 1 : opt.maxbasis), tmpl.basis(:, opt.maxbasis + 1 : end), paramSR, prod(opt.tmplsize));  
k = sum(posOri);             % the number of selected feature
temp = find(posOri);
P = zeros(N,k);              % N is the number of pixels in one template, P is k hot vectors, each vector is a feature
for i = 1:k
    P(temp(i),i) = 1;
end
opt.P = P;
ori = repmat(tmpl.basis(:, 1 : opt.maxbasis), 1, 5);  %repeat target template   *20 -> *100
pos = ori;
for f = 1:size(data,3)    %iterate all images
  frame = double(data(:,:,f))/256;
  
  % do tracking
   param = estwarp_condens(frame, tmpl, param, opt);
   % param.est = affparam2mat(param.param(:,maxidx));
   % param.wimg = reshape(oriData(:,maxidx), sz);
   % param.err = reshape(oriData(:,maxidx) - tmpl.basis * coef(:, maxidx), sz);    ????????
   % param.recon = reshape(tmpl.basis(:, 1 : opt.maxbasis) * coef(1 : opt.maxbasis, maxidx), sz);

  % do update
  wimgs = [wimgs, param.wimg(:)];
  tmpl.basis(:, opt.maxbasis + 1 : end) = sampleNeg(frame, param.est', opt.tmplsize, opt.negativeBasis);
  pos(:, mod(f - 1, 5) * 10 + 1 : mod(f - 1, 5) * 10 + 10) = samplePos(frame, param.est', opt.tmplsize);
  pos(:, mod(f - 1, 5) * 10 + 11 : mod(f - 1, 5) * 10 + 20) = samplePos(frame, param.est', opt.tmplsize);
  posOri = selectFeature(ori, tmpl.basis(:, opt.maxbasis + 1 : end), paramSR, prod(opt.tmplsize));  
  posCur = selectFeature(pos, tmpl.basis(:, opt.maxbasis + 1 : end), paramSR, prod(opt.tmplsize));  
  sel = posOri & posCur;
  k = sum(sel);             % the number of selected feature
  P = zeros(N,k);
  temp = find(sel);
  for i = 1:k
      P(temp(i),i) = 1;
  end
  opt.P = P;
  if (size(wimgs,2) >= opt.batchsize )
        [A, B, tmpl.basis(:, 1 : opt.maxbasis)] = updateBase(A, B, tmpl.basis(:, 1 : opt.maxbasis), wimgs, opt);        
        wimgs = [];
  end
  
  duration = duration + toc;
  
  % Save the results 
  res = affparam2geom(param.est);
  p(1) = round(res(1));
  p(2) = round(res(2));
  p(3) = res(3) * opt.tmplsize(2);
  p(4) = res(5) * (opt.tmplsize(1) / opt.tmplsize(2)) * p(3);
  p(5) = res(4);
  p(3) = round(p(3));
  p(4) = round(p(4));
  savedRes = [savedRes; p];
  
  drawopt = drawtrackresult(drawopt, f, frame, tmpl, param, []);
  tic;
end
duration = duration + toc;
save([title '_ONNDL'], 'savedRes');
fprintf('%d frames took %.3f seconds : %.3fps\n',f,duration,f/duration);

