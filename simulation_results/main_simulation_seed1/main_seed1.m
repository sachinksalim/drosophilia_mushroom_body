%! before running this code, please add all subfolders into path
clear

% default parameters

odor_N = 110;
PN_N = 23; 
KC_d = [45,45];
KC_input_N = 6;
total_T = 2500;
deltat = 0.5;
A = 0.005; 
taus = 50;

sigmas = [0 5 10 20 38 100]; % 0 is no inhibition, 100 is all to all inhibition
gsyn_values = [0 -0.15 -0.05 -0.02 -0.013  -0.01];
connectivity_modes = ["full random" "local random"];

% create empty experiment
experiment = struct;
exp_i = 1;

% set random seed of experiment
rand_seed = 1;

% load PN responses
load("odor_PN_t.mat")

% PN-KC connections
for connect_mode = connectivity_modes
    w_matrix = PN_KC_connect(PN_N,KC_d,KC_input_N,connect_mode,rand_seed,false);
    
    for inh_i = 1:length(sigmas)
        experiment(exp_i).connectivity_mode = connect_mode;
        experiment(exp_i).w_matrix = w_matrix;
        sigma = sigmas(inh_i);
        experiment(exp_i).sigma = sigma;
        gsyn = gsyn_values(inh_i);
        experiment(exp_i).gsyn = gsyn;
        if (sigma == 0)
            W = zeros(KC_d(1)*KC_d(2),KC_d(1)*KC_d(2));
        elseif (sigma >50)
            W = ones(KC_d(1)*KC_d(2),KC_d(1)*KC_d(2));
        else
            W = DecayingConnectivityMatrix(KC_d,sigma);
        end
        experiment(exp_i).ihibitory_W = W;
        tic
        
        % odors to be fitted
        odor_set = 1:odor_N;
        
        % place holder for evaluation
        sparseness = zeros(length(odor_N));
        fraction = zeros(length(odor_N));
        response_counts = zeros(length(odor_N),KC_d(1)*KC_d(2));
        for odorID_i = 1: length(odor_set)
            
            % generate input from PN
            test_odor =squeeze(odor_PN_t(odor_set(odorID_i),:,:));
            %test_odor = test_odor(1:PN_N, :);
            KC_input = zeros(KC_d(1), KC_d(2), total_T);
        
            for i = 1:KC_d(1)
                KC_input(i,:,:) = A*squeeze(w_matrix(i,:,:))*test_odor;
            end
                
            % simulate KC responses to one odor
            
            [spiketimes]=LIF2D_simple_network(KC_d,W,gsyn,taus,KC_input);
            if ~isempty(spiketimes)
                [sck, f_kc, counts] = Sparsity(spiketimes,KC_d); % sparsness
                sparseness(odorID_i) = sck;
                fraction(odorID_i) = f_kc;
                response_counts(odorID_i,:) = counts;
            end
        end
        sparseness(sparseness == 0) = 1;
        experiment(exp_i).sparseness = sparseness;
        experiment(exp_i).fraction = fraction;
        experiment(exp_i).KC_response = response_counts;
        toc
        disp([num2str(exp_i) "/12 completed"]);
        exp_i = exp_i + 1;
    end
end

save('simulation_seed1.mat','experiment');
        







