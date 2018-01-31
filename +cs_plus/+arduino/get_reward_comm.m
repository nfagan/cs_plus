function comm = get_reward_comm(conf)

%   GET_REWARD_COMM -- Get an instantiated BrainsSerialManagerPaired
%     object.
%
%     OUT:
%       - `comm` (BrainsSerialManagerPaired)

import brains.arduino.BrainsSerialManagerPaired;

if ( nargin < 1 )
  conf = cs_plus.config.load(); 
else
  cs_plus.util.assertions.assert__is_config( conf );
end

SERIAL = conf.SERIAL;

is_master = conf.INTERFACE.is_master_arduino;

if ( is_master )
  role = 'master';
else
  role = 'slave';
end

Alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

port = SERIAL.ports.reward;
% rwd_channels = SERIAL.reward_channels;
rwd_indices = SERIAL.outputs.reward;
rwd_channels = arrayfun( @(x) x, Alphabet(rwd_indices), 'un', false );
messages = struct();
comm = BrainsSerialManagerPaired( port, messages, rwd_channels, role );

end