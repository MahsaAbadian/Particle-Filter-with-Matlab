
%% clear everything
clear all
close all
clc

%% initialize the problem variables
%% the region that is serviced by a GDB is divided into m * n square cells,
m=300;
n=300; 
max_v= m/300;%%<1/100 m maximum x velocity
max_p=100; %% maximum power an SU can use

%% initiate the problem: 
%% generate real pu locations 
PUnum=1;
PUs=zeros(1,PUnum);

for i=1:PUnum  
 PUs(1,i)= complex(fix(rand*m), fix(rand*n));
 PUs(2,i)= complex(rand*max_v*(-1)^(fix(rand*2)) , rand*max_v*(-1)^(fix(rand*2))); %i->fix(rand*2))
end


%%initial the filtering parameters
T=1; %% time difference between two queries
N = 3000; 
sigma=complex(0.01, 0.01); %%noise intensity


sys_noise_cov = [1/3*T^3, 1/2*T^2; 1/2*T^2, T]*sigma; % Noise covariance in the system 
F=[1 T; 0 1];
particles=zeros(2,N);

for i=1:N
  particles(1,i)=complex(fix(rand*m), fix(rand*n)); 
  particles(2,i)=complex(rand*max_v*((-1)^(fix(rand*2))) , rand*max_v*((-1)^(fix(rand*2))));
end

entropy=zeros(1,70);
distance=zeros(1,70);

threshold=3.6;
it=70;
for k=1:70 
    
                                %%% initialization, illastration, evaluation , and end condition %%%  
    %% initialization
    
    weights=zeros(1,N)+1/N;
    
    % the PUs will move:  
    for j=1:PUnum
      PUs(:,j) = F*PUs(:,j) + sqrt(sys_noise_cov) * [complex(randn, randn); 0];      
    end
    
    % generate random location for SU
    loc = complex(fix(rand*m), fix(rand*n));
 
    %% illastration
    if ( fix((k-1)/5) == (k-1)/5 )
     %% figure(k)
      %%plot(particles,'.b',PUs(1,:),'.r')
    endif    
    
    %% evaluation
    % putting particles with fix equal values together and counting the number of them in order to calculate the 
    % real weights of particles which shows the concentration in some point.
    
    l = 10;
    BParticles = (fix(particles(1,:)./l))*l; 
    uniqueBParticles = unique(BParticles);
    P = zeros(size(uniqueBParticles));
    uBParticleNum = size(uniqueBParticles,2);

    for i = 1:uBParticleNum
      P(i) = sum( uniqueBParticles(i)==BParticles );
    end
    
   % calculation of entropy as a parameter to show the end of algorithm
     entropy(1,k) =  -sum((P/N).*log(P/N));

   if entropy(1,k)<threshold 
    it=k;
    break;
   endif
   
   % sorting weights in order to get most concentrated points which are the answers
   

    fixedParticles=(fix(particles(1,:))); 
   
    uniquefixedParticles = unique(fixedParticles);
    
    particleNum = size(uniquefixedParticles,2);
    
    particlesDensity = zeros(size(uniquefixedParticles));
    
    for i=1:particleNum
      particlesDensity(i) = sum(uniquefixedParticles(i)==fixedParticles);
    end
   
   [val, sortindx] = sort(particlesDensity);
   
   distance(1,k) = min(abs(uniquefixedParticles(sortindx(particleNum-4:particleNum))-PUs(1,1)));
   
       
                                      %%%%%%%%%%%%%%Here, we do the particle filter%%%%%%%%%%%%%%%%%
    
    
    %% # measurment
    p = DBreq(loc, PUs, max_p);
    
    
    %% # prediction
    
    % these are needed parameters initialized
    particles_star=zeros(2,N);  
    count=0;
    
    for j = 1:N
        % the particles should move with the PU motion model in each iteration
        particles_star(:,j) = F*particles(:,j)+ sqrt(sys_noise_cov)*[complex(randn, randn); complex(randn, randn);];   
        % with these new updated particle locations, update the observations for each of these particles.
        z(j) = h(abs(particles_star(1,j)-loc), max_p);
        % counting the number of particles in the same region that we know atleast a PU should exist there 
        %inorder to update the weight with respect to it
        if p == z(j) 
          count++;
        end           
    end    
    
    
    %% # updating the weights
    for j = 1:N    
      if (z(j)==p) % this particle might be a true locat
        weights(j)= 1/count;
      elseif (z(j) < p) % we know this particle does not exist! 
        weights(j)=0;
      end
      % otherwise we dont know anything
    end
    
    % Normalize to form a probability distribution (i.e. sum to 1).
    weights = weights./sum(weights);
    weights_resample_update=zeros(1,n);
    
    %% # Resampling: From this new distribution, now we randomly sample from it to generate our new estimate particles
    for j = 1 : N
        particles(:,j) = particles_star(:,find(rand <= cumsum(weights),1));
    end   
       
end



figure(71)
plot(uniquefixedParticles(sortindx(particleNum-5:particleNum)),'.b',PUs(1,:),'.r')
figure(72)
plot(particles,'.b',PUs(1,:),'.r')
figure(73)
plot([1:it],entropy(1:it));
figure(74)
plot([1:it],distance(1:it));


