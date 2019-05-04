function big_loop2()

n_digits=[4,4,4,4,4,4,4,4,4];
n_colors=[2,3,4,5,6,7,8,9,10];

n_loop=size(n_digits,2);

for i=1:n_loop
    n_digit=n_digits(i);
    n_color=n_colors(i);
    one_loop2(n_digit,n_color);
end


end

function one_loop2(n_digit,n_color)

ep=0.5;
delta=0.1;

setting_path=['./',num2str(n_digit),'_',num2str(n_color),'/']
if ~exist(setting_path, 'dir')
    mkdir(setting_path)
end

load([setting_path,'meta_data']);
load([setting_path,'theta_data']);

hist_array=meta_data.hist_array;
Pxs=theta_data.Pxs;
taus=theta_data.taus;
theta=theta_data.theta;



end

function [kn,k,n_queries]=total_CAL_queries(theta,ep,delta,n_digit,n_color)

log2 = @(x)log(x)/log(2);
n_queries=log2(1/ep);
H_size=n_color^n_digit;
k=2*theta*(log((1/ep)*H_size/delta));
kn=k*n_queries;

end