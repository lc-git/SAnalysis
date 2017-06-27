function param = estwarp_condens(frm, tmpl, param, opt)
n = opt.numsample;
sz = size(tmpl.mean);
N = sz(1)*sz(2);

if ~isfield(param,'param')
  param.param = repmat(affparam2geom(param.est(:)), [1,n]);  % 6 parameters -> 6*n
else
  cumconf = cumsum(param.conf);
  idx = floor(sum(repmat(rand(1,n),[n,1]) > repmat(cumconf,[1,n])))+1;
  param.param = param.param(:,idx);
end

% 'affsig',  These are the standard deviations of
% the dynamics distribution, that is how much we expect the target
% object might move from one frame to the next.  The meaning of each
% number is as follows:
%    affsig(1) = x translation (pixels, mean is 0)
%    affsig(2) = y translation (pixels, mean is 0)
%    affsig(3) = x & y scaling
%    affsig(4) = rotation angle
%    affsig(5) = aspect ratio
%    affsig(6) = skew angle
% 'affsig' = [4,4,.005,.00,.001,.00]

param.param = param.param + randn(6,n).*repmat(opt.affsig(:),[1,n]);
wimgs = warpimg(frm, affparam2mat(param.param), sz);
data = reshape(wimgs,[N,n]);							 % data is particles sampled according to affine parameters and Gaussian
data = bsxfun(@rdivide, data, sqrt(sum(data .* data)));  % normalize

oriData = data;
data = opt.P' * data;		% P is N*k feature matrix, [k, N] * [N, n] -> [k, n], k features in each particle
base = opt.P' * tmpl.basis; % features in templates [k, N] * [N, length of basis] -> [k, length of basis]
tic;
[coef, ~, ~] = RNNSC(data, base, 1, 0, true && opt.useGpu); % coef is [length of basis, n]
toc 
diff = sum(base(:, 1 : opt.maxbasis) * coef(1 : opt.maxbasis, :)) - sum(base(:, opt.maxbasis + 1 : end) * coef(opt.maxbasis + 1 : end, :));
% sum([k, n])  -> [1, n]  for each particle, get the diffirence between target template and trivial template

param.coef = coef;
  
% Used in calculating particle confidence.
param.conf = exp(double(diff) ./opt.condenssig)';

param.conf = param.conf ./ sum(param.conf);
[maxprob,maxidx] = max(param.conf);
if maxprob == 0
    error('overflow!');
end
param.est = affparam2mat(param.param(:,maxidx));
param.wimg = reshape(oriData(:,maxidx), sz);
param.err = reshape(oriData(:,maxidx) - tmpl.basis * coef(:, maxidx), sz);
param.recon = reshape(tmpl.basis(:, 1 : opt.maxbasis) * coef(1 : opt.maxbasis, maxidx), sz);
if exist('coef', 'var')
    param.bestCoef = coef(:,maxidx);
end
