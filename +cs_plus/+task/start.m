
function err = start(opts)

%   START -- Attempt to setup and run the task.
%
%     OUT:
%       - `err` (double, MException) -- 0 if successful; otherwise, the
%         raised MException, if setup / run fails.

if ( nargin < 1 )
  opts = [];
else
  cs_plus.util.assertions.assert__is_config( opts );
end

tracker = [];

try
  opts = cs_plus.task.setup( opts );
catch err
  if ( ~isempty(opts) )
    tracker = opts.TRACKER; 
  end
  cs_plus.task.cleanup( tracker );
  cs_plus.util.print_error_stack( err );
  return;
end

try
  err = 0;
  cs_plus.task.run( opts );
  cs_plus.task.cleanup( tracker );
catch err
  cs_plus.task.cleanup( tracker );
  cs_plus.util.print_error_stack( err );
end

end