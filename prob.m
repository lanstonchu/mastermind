

function big_loop()

n_digits=[4,4,4,4,4,4,4,4,4];
n_colors=[2,3,4,5,6,7,8,9,10];

n_loop=size(n_digits,2);

setting_infos=[];
for i=1:n_loop
    n_digit=n_digits(i);
    n_color=n_colors(i);
    [dist_2nd_best,ep,kn,k,n_queries]=one_loop(n_digit,n_color);
    setting_infos=[setting_infos,[dist_2nd_best;ep;kn;k;n_queries]];
end

setting_infos
end

function [dist_2nd_best,ep,kn,k,n_queries]=one_loop(n_digit,n_color)

delta=0.1;

setting_path=['./',num2str(n_digit),'_',num2str(n_color),'/']
if ~exist(setting_path, 'dir')
    mkdir(setting_path)
end


all_comb=all_combinations(n_color,n_digit);

% h_star=[1,2,3,3];
h_star=1:n_digit; %typical h_star
% create_record(h_star,all_comb,n_color,setting_path); %hide this line to save run time

record_meta_reordered=relationship_flag_vs_dist(n_digit,setting_path)

[sorted_dist, hist_dist]=check_unique_dist(setting_path);

[theta,Pxs]=get_theta(sorted_dist,n_color,setting_path);

dist_2nd_best=record_meta_reordered(2,4);
ep=dist_2nd_best;
[kn,k,n_queries]=total_CAL_queries(theta,ep,delta,n_digit,n_color);

end

function [kn,k,n_queries]=total_CAL_queries(theta,ep,delta,n_digit,n_color)

log2 = @(x)log(x)/log(2);
n_queries=log2(1/ep);
H_size=n_color^n_digit;
k=2*theta*(log((1/ep)*H_size/delta));
kn=k*n_queries;

end

function [theta,Pxs]=get_theta(taus,n_color,setting_path)

n_tau=size(taus,2);

Pxs=[];
Px_last=0;
for i=1:n_tau
    if Px_last<1
        tau=taus(1,i);
        disp(['Now we are looking at tau ',num2str(i),': ',num2str(tau)])
        Px=DIS(tau,n_color,setting_path);
        Pxs=[Pxs,Px];
        Px_last=Px;
    elseif Px_last==1 % the last Px is already 1
        Px=1; % new Px would also be 1
        Pxs=[Pxs,Px];
        Px_last=Px;
    else
        error('Px cant be larger than 1')
    end
end

logic=(taus~=0);
thetas=Pxs(logic)./taus(logic);
theta=max(thetas);

theta_data.Pxs=Pxs;
theta_data.taus=taus;
theta_data.theta=theta;

save([setting_path,'theta_data'],'theta_data');

end

function Px=DIS(tau,n_color,setting_path)

load([setting_path,'data_array']);

all_comb=record_array.comb;
red=record_array.red;
white=record_array.white;
dist=record_array.dist;
n_comb=size(all_comb,1);

logic=(dist<=tau);
cases_sel=all_comb(logic,:);
n_sel=size(cases_sel,1);

DIS_flags=[];
for i=1:n_comb
    i
    h_i=all_comb(i,:);
    
    stop_ij=0;
    DIS_flag=0;
    
    j=0;
    while stop_ij==0 && j<=(n_sel-1)
        j=j+1;
        h1=cases_sel(j,:);
        
        k=0;
        while stop_ij==0 && k<=(n_sel-1)
            k=k+1;
            h2=cases_sel(k,:);
            
            [red1, white1]=give_flag(h1,h_i,n_color);
            [red2, white2]=give_flag(h2,h_i,n_color);
            
            if red1~=red2 || white1~=white2
                stop_ij=1;
                DIS_flag=1;
            end
            
        end
    end
    DIS_flags=[DIS_flags;DIS_flag];
    
end

num_DIS_cases=sum(DIS_flags);
Px=num_DIS_cases/n_comb;

end

function [sorted_dist, hist_dist]=check_unique_dist(setting_path)

load([setting_path,'data_array']);

dist=record_array.dist;

unique_dist=unique(dist)';
n_bin=size(unique_dist,2);

sorted_dist=sort(unique_dist); %result will be in ascending order
diff_dist=diff(sorted_dist);
edge=[sorted_dist(1)-1,sorted_dist(1:(n_bin-1))+diff_dist/2,sorted_dist(n_bin)+1];

hist_dist=histcounts(dist,edge);

hist_array=[sorted_dist;hist_dist];

meta_data.hist_array=hist_array;
save([setting_path,'meta_data'],'meta_data');

end

function create_record(h_star,all_comb,n_color,setting_path)

n_comb=size(all_comb,1);
d=size(h_star,2);

record=[];
for i=1:n_comb
    i
    h_i=all_comb(i,:);
    [red, white]=give_flag(h_star,h_i,n_color);
    dist=distance(h_star,h_i,all_comb,n_color);
    new_row=[h_i,red, white, dist];
    record=[record; new_row];
end

record_array.comb=record(:,1:d);
record_array.red=record(:,end-2);
record_array.white=record(:,end-1);
record_array.dist=record(:,end);

save([setting_path,'data_array'],'record_array')

end

function record_meta_reordered=relationship_flag_vs_dist(n_digit,setting_path)


load([setting_path,'data_array']);

red=record_array.red;
white=record_array.white;
dist=record_array.dist;

record_meta=[];
for red_i=0:n_digit
    for white_j=0:(n_digit-red_i)
        
        logic1=(red==red_i);
        logic2=(white==white_j);
        logic=logical(logic1.*logic2);
        
        num_cases=sum(logic);
        dist_sel=dist(logic,:);
        mu=mean(dist_sel);
        sigma=std(dist_sel);
        max_dist=max(dist_sel);
        min_dist=min(dist_sel);
        
        if isempty(max_dist)
            max_dist=NaN;
        end
        if isempty(min_dist)
            min_dist=NaN;
        end
        row_new=[red_i,white_j,num_cases,mu,sigma,max_dist,min_dist];
        record_meta=[record_meta;row_new];
        
    end
end

dist_mean=record_meta(:,4);
[~,idx] = sort(dist_mean);
record_meta_reordered=record_meta(idx,:);

end

function [red, white]=give_flag(h,x,n_color)

% h and x are row vector, ranging from 1 to n

n_h=size(h,2);
n_x=size(x,2);

if n_h~=n_x
    error('n_h and n_x should be same')
end

hist_h=histcounts(h,(1-0.5):(n_color+0.5));
hist_x=histcounts(x,(1-0.5):(n_color+0.5));

red=sum(x==h);
white=sum(min(hist_h,hist_x))-red;

end

function prob_neq=distance(h1,h2,all_comb,n_color)

n_1=size(h1,2);
n_2=size(h2,2);
n_comb=size(all_comb,1);

if n_1~=n_2
    error('n_1 and n_2 should be same')
end

count_neq=0;
for i=1:n_comb
    h_i=all_comb(i,:);
    [red1, white1]=give_flag(h1,h_i,n_color);
    [red2, white2]=give_flag(h2,h_i,n_color);
    
    if red1~=red2 || white1~=white2
        count_neq=count_neq+1;
    end
    
end

prob_neq=count_neq/n_comb;

end

function matrix_combin=all_combinations(n,d)

% d is the number of digit

one_to_n=(1:n)';

matrix_combin=[];
for i=1:d
    
    col_i=repmat(repelem(one_to_n,n^(d-i),1),n^(i-1),1);
    matrix_combin=[matrix_combin, col_i];
    
end

end