function out = parchk(in, defaults)
% # Helper to validate function parameters
% ## Usage
% * `out = parchk(in, defaults)`
%
% ## Description
% Validates a set of function parameters, that is, checks for missing
% parameters, sets defaults, and complains about unknown parameters.
% Parameters are name-value pairs.
%
% ## Input
% * `in`: Struct of parameters to validate.
% * `defaults`: Struct of default parameters.
%
% ## Output
% * `out`: Struct of validated parameters.
%
% ## Authors
% 2017-present -- Roland Hostettler <roland.hostettler@angstrom.uu.se>

%{
% This file is part of the libsmc Matlab toolbox.
%
% libsmc is free software: you can redistribute it and/or modify it under 
% the terms of the GNU General Public License as published by the Free 
% Software Foundation, either version 3 of the License, or (at your option)
% any later version.
% 
% libsmc is distributed in the hope that it will be useful, but WITHOUT ANY
% WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
% FOR A PARTICULAR PURPOSE. See the GNU General Public License for more 
% details.
% 
% You should have received a copy of the GNU General Public License along 
% with libsmc. If not, see <http://www.gnu.org/licenses/>.
%}

    narginchk(2, 2);
    out = defaults;
    fields = fieldnames(in);
    for i = 1:length(fields)
        if isfield(defaults, fields{i})
            out.(fields{i}) = in.(fields{i});
        else
            warning('Discarding unknown parameter ''%s''.', fields{i});
        end
    end
end
