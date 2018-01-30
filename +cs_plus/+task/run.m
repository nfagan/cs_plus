
function run(opts)

%   RUN -- Run the task based on the saved config file options.
%
%     IN:
%       - `opts` (struct)

INTERFACE = opts.INTERFACE;
STIMULI = opts.STIMULI;
TRACKER = opts.TRACKER;
TIMER = opts.TIMER;

fix_targ = STIMULI.fix_square;
cs_stim = STIMULI.cs;

cstate = 'fixation';
first_entry = true;
is_debug = INTERFACE.debug;

while ( true )
  
  TRACKER.update_coordinates();
  fix_targ.update_targets();
  cs_stim.update_targets();
  
  %   FIXATION
  if ( strcmp(cstate, 'fixation') )
    if ( first_entry )
      log_entry( cstate, is_debug );
      TIMER.reset_timers( cstate );
      TIMER.reset_timers( 'aq_fixation' );
      fix_targ.reset_targets();
      drew_fix_targ = false;
      looked_to_target = false;
      first_entry = false;
    end
    
    if ( ~drew_fix_targ )
      fix_targ.draw();
      sflip( opts );
      drew_fix_targ = true;
    end
    
    if ( fix_targ.in_bounds() )
      looked_to_target = true;
    elseif ( looked_to_target )
      log_exit( cstate, is_debug );
      cstate = 'fixation_error';
      first_entry = true;
      continue;
    end
    
    if ( TIMER.duration_met('aq_fixation') && ~looked_to_target )
      log_exit( cstate, is_debug );
      cstate = 'fixation_error';
      first_entry = true;
      continue;
    end
    
    if ( fix_targ.duration_met() )
      log_exit( cstate, is_debug );
      cstate = 'cs_presentation';
      first_entry = true;
    end
  end
  
  %   CS_PRESENTATION
  if ( strcmp(cstate, 'cs_presentation') )
    if ( first_entry )
      log_entry( cstate, is_debug );
      sflip( opts );
      drew_cs = false;
      TIMER.reset_timers( cstate );
      TIMER.reset_timers( 'aq_cs' );
      cs_stim.reset_targets();
      first_entry = false;
    end
    
    if ( ~drew_cs )
      cs_stim.draw();
      sflip( opts );
      drew_cs = true;
    end
    
    if ( TIMER.duration_met('aq_cs') && ~looked_to_target )
      log_exit( cstate, is_debug );
      cstate = 'cs_error';
      first_entry = true;
      continue;
    end
    
    if ( cs_stim.in_bounds() )
      looked_to_target = true;
    elseif ( looked_to_target )
      log_exit( cstate, is_debug );
      cstate = 'cs_error';
      first_entry = true;
      continue;
    end
    
    if ( cs_stim.duration_met() )
      log_exit( cstate, is_debug );
      cstate = 'cs_reward';
      first_entry = true;
      continue;
    end
    
    if ( TIMER.duration_met(cstate) )
      log_exit( cstate, is_debug );
      cstate = 'cs_reward';
      first_entry = true;
    end
  end
  
  %   FIXATION_ERROR
  if ( strcmp(cstate, 'fixation_error') )
    if ( first_entry )
      sflip( opts );
      log_entry( cstate, is_debug );
      TIMER.reset_timers( cstate );
      first_entry = false;
    end
    
    if ( TIMER.duration_met(cstate) )
      log_exit( cstate, is_debug );
      cstate = 'fixation';
      first_entry = true;
    end
  end
  
  %   CS_ERROR
  if ( strcmp(cstate, 'cs_error') )
    if ( first_entry )
      sflip( opts );
      log_entry( cstate, is_debug );
      TIMER.reset_timers( cstate );
      first_entry = false;
    end
    
    if ( TIMER.duration_met(cstate) )
      log_exit( cstate, is_debug );
      cstate = 'fixation';
      first_entry = true;
    end
  end
  
  %   CS_REWARD
  if ( strcmp(cstate, 'cs_reward') )
    if ( first_entry )
      sflip( opts );
      log_entry( cstate, is_debug );
      TIMER.reset_timers( cstate );
      first_entry = false;
    end
    
    if ( TIMER.duration_met(cstate) )
      log_exit( cstate, is_debug );
      cstate = 'fixation';
      first_entry = true;
    end
  end

  [key_pressed, ~, key_code] = KbCheck();

  if ( key_pressed )
    if ( key_code(INTERFACE.stop_key) ), break; end
  end

end

end

function sflip(opts)
Screen( 'Flip', opts.WINDOW.index );
end

function log_entry(name, is_debug)
log_debug( sprintf('Entered "%s"', name), is_debug );
end

function log_exit(name, is_debug)
log_debug( sprintf('Exited "%s"', name), is_debug );
end

function log_debug(msg, is_debug)
if ( is_debug ), fprintf( '\n%s', msg ); end
end
	