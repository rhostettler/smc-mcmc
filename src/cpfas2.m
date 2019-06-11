function [x, sys] = cpfas2(model, y, xtilde, theta, J, par)
% Conditional particle filter with ancestor sampling (non-Markovian models)
%
% USAGE
%   x = CPFAS(model, y)
%   [x, sys] = CPFAS(model, y, xtilde, theta, J, par)
% 
% DESCRIPTION
%   
%
% PARAMETERS
%   model   Model structure
%   y       Measurements, y[1:N]
%   xtilde  Seed trajectory, xtilde[1:N] (optional, a bootstrap particle
%           filter is used to generate a seed trajectory if omitted)
%   theta   Additional parameters (optional)
%   J       Number of particles (optional, default: 100)
%   par     Additional algorithm parameters:
%
%           sample(model, y, x, theta)
%               Function to sample new particles (used for the J-1
%               particles; optional, default: sample_bootstrap)
%
%           calculate_incremental_weights(model, y, xp, x, theta)
%               Function to calculate the incremental particle weights
%               (must match the sampling function defined above; optional,
%               default: calculate_incremental_weights_bootstrap)
%
%           sample_ancestor_index(model, y, xtilde, x, lw, theta)
%               Function to sample the ancestor indices (optional, default:
%               sample_ancestor_index)
%
%
% RETURNS
%   x       The newly sampled trajectory (Nx*N)
%   sys     Struct of the particle system containing:
%
%           x       Raw particles (not ordered according to their lineages)
%           w       Raw particle weights corresponding to x
%           alpha   Ancestor indices for all particles
%           r       Resampling indicator (always true for CPF-AS)
%           state   Internal state of the ancestor index sampling
%                   algorithm, see the corresponding algorithm for details
%
% AUTHOR
%   2017-2019 -- Roland Hostettler <roland.hostettler@aalto.fi>

% TODO
%   * 

    %% Defaults
    narginchk(2, 6);
    if nargin < 4
        theta = [];
    end
    if nargin < 5 || isempty(J)
        J = 100;
    end

    % Default parameters (importance density, weights, etc.)
    if nargin < 6
        par = struct();
    end
    def = struct( ...
        'sample', @sample_bootstrap2, ...
        'calculate_incremental_weights', @calculate_incremental_weights_bootstrap2, ...
        'sample_ancestor_index', @sample_ancestor_index ...
    );
    par = parchk(par, def);

    %% Prepare and preallocate
    % Prepend a NaN measurement (for x[0] where we don't have a 
    % measurement)
    [Ny, N] = size(y);
    N = N+1;
    y = [NaN*ones(Ny, 1), y];

    % Expand theta properly such that we have theta(:, n)
    [~, Nc] = size(theta);
    switch Nc
        case 0
            % Empty theta => create vector of NaNs
            theta = NaN*ones(1, N);
        case 1
            % Single (static parameter), expand to be Nc*N
            theta = theta*ones(1, N);
        case N-1
            theta = [NaN, theta];
        otherwise
            error('Parameter vector must either be empty, M x 1, or M x N');
    end
    
    % Determine state size
    Nx = size(model.px0.rand(1), 1);
    sys = initialize_sys(N, Nx, J);
    
    %% Initialize seed trajectory
    % If no trajectory is given (e.g. for the first iteration), we draw an
    % initial trajectory from a bootstrap particle filter which helps to
    % speed up convergence.
    if nargin < 3 || isempty(xtilde) || all(all(xtilde == 0))
if 0
        % Default trajectory: Use a regular PF to calculate a degenerate 
        % trajectory (see below)
        [~, tmp] = pf(y(:, 2:N), theta(:, 2:N), model, J);
        
        % Sample trajectory according to the final filter weights
        beta = sysresample(tmp(end).wf);
        j = beta(randi(J, 1));
        xf = cat(3, tmp.xf);
        xtilde = squeeze(xf(:, j, :));
        
        % TODO: Ugly hack; can be solved on the line above already
        if Nx == 1
            xtilde = xtilde.';
        end
end
        xtilde = zeros(Nx, N);
    end
    
    %% Preallocate
    xf = zeros(Nx, J, N);
    
    %% Initialize
    % Draw initial particles
    xf(:, 1:J-1, 1) = model.px0.rand(J-1);
    xf(:, J, 1) = xtilde(:, 1);
    w = 1/J*ones(1, J);
    lw = log(1/J)*ones(1, J);
    
    % Store initial state
if 0
    sys(1).x = x;
    sys(1).w = w;
end
    
    %% Iterate over the data
    for n = 2:N
        %% Sampling
        % Resample and sample ancestor index
        alpha = sysresample(w);                         % TODO: Should we be able to change this through par?
        [alpha(J), state] = par.sample_ancestor_index(model, y, xtilde(:, n:N), xf(:, :, 1:n-1), lw, theta);
        xf(:, :, 1:n-1) = xf(:, alpha, 1:n-1);
        
        % Sample J-1 particles and set Jth particle
        xf(:, 1:J-1, n) = par.sample(model, y(:, 1:n), xf(:, 1:J-1, 1:n-1), theta(:, 1:n));
        xf(:, J, n) = xtilde(:, n);
        
        %% Calculate weights
        lw = par.calculate_incremental_weights(model, y(:, 1:n), xf(:, :, 1:n), theta(:, 1:n));
        w = exp(lw-max(lw));
        w = w/sum(w);
        lw = log(w);

        if any(isnan(w)) || any(w == Inf)
            warning('NaN and/or Inf in particle weights.');
        end
        
        %% Store
if 0
        sys(n).x = x;
        sys(n).w = w;
        sys(n).r = true;
        sys(n).alpha = alpha;
        sys(n).state = state;
end
    end
    
    %% Sample trajectory
    beta = sysresample(w);
    j = beta(randi(J, 1));
    x = reshape(xf(:, j, :), [Nx, N]);
end