function run(opts)

%   RUN -- Run the task based on the saved config file options.
%
%     IN:
%       - `opts` (struct)

INTERFACE = opts.INTERFACE;
STIMULI = opts.STIMULI;
IMAGES = opts.IMAGES;
TRACKER = opts.TRACKER;
TIMER = opts.TIMER;
REWARDS = opts.REWARDS;
STRUCTURE = opts.STRUCTURE;

comm = opts.SERIAL.comm;

fix_targ = STIMULI.fix_square;
cs_stim = STIMULI.cs;
cs_reward_stim = STIMULI.reward_size;

cstate = 'new_trial';
first_entry = true;
is_debug = INTERFACE.debug;

current_n_rewards = [];
reward_key_timer = NaN;
reward_timeout = 0.5;

PLEX_SYNC = struct();
PLEX_SYNC.timer = NaN;
PLEX_SYNC.sync_times = nan( 1e4, 1 );
PLEX_SYNC.sync_stp = 1;
PLEX_SYNC.frequency = opts.STRUCTURE.plex_sync_frequency;
PLEX_SYNC.start_time = TIMER.get_time( 'task' );

DATA = struct();
TRIAL_NUMBER = 0;
PROGRESS = struct();
errors = struct( ...
  'broke_initial_fixation', false ...
  , 'initial_fixation_not_acquired', false ...
  , 'broke_cs_fixation', false ...
  , 'cs_fixation_not_acquired', false ...
);
n_correct = 0;
n_errors = 0;

comm.sync_pulse( 1 );

while ( true )
  
  if ( isnan(PLEX_SYNC.timer) || toc(PLEX_SYNC.timer) >= PLEX_SYNC.frequency )
    comm.sync_pulse( 2 );
    PLEX_SYNC.sync_times(PLEX_SYNC.sync_stp) = TIMER.get_time( 'task' );
    PLEX_SYNC.sync_stp = PLEX_SYNC.sync_stp + 1;
    PLEX_SYNC.timer = tic();
  end
  
  TRACKER.update_coordinates();
  fix_targ.update_targets();
  cs_stim.update_targets();
  
  %   NEW_TRIAL
  if ( strcmp(cstate, 'new_trial') )
    current_n_rewards = randperm( 3, 1 );
    image_index = current_n_rewards;
    if ( current_n_rewards > numel(IMAGES.reward_size) )
      msg = sprintf( 'Requested image %d, but there are only %d images' ...
        , current_n_rewards, numel(IMAGES.reward_size) );
      log_debug( msg, is_debug );
      image_index = numel( IMAGES.reward_size );
    end
    if ( image_index > 0 )
      cs_reward_stim.image = IMAGES.reward_size(image_index).image;
    end
    if ( TRIAL_NUMBER > 0 )
      tn = TRIAL_NUMBER;
      DATA(tn).events = PROGRESS;
      DATA(tn).errors = errors;
    end
    
    any_errors = any( structfun(@(x) x, errors) );
    n_correct = n_correct + ~any_errors;
    n_errors = n_errors + any_errors;
    
    clc;
    fprintf( '\n N correct: %d', n_correct );
    fprintf( '\n N errors: %d', n_errors );
    fprintf( '\n N total: %d', TRIAL_NUMBER );
    fprintf( '\n Ellapsed time: %0.3f', TIMER.get_time('task') );
    
    TRIAL_NUMBER = TRIAL_NUMBER + 1;
    PROGRESS = structfun( @(x) nan, PROGRESS, 'un', false );
    errors = structfun( @(x) false, errors, 'un', false );
    log_debug( sprintf('Current rewards: %d', current_n_rewards), is_debug );
    cstate = 'fixation';
    first_entry = true;
  end
  
  %   FIXATION
  if ( strcmp(cstate, 'fixation') )
    if ( first_entry )
      log_entry( cstate, is_debug );
      PROGRESS.(cstate) = TIMER.get_time( 'task' );
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
      errors.broke_initial_fixation = true;
      cstate = 'fixation_error';
      first_entry = true;
      continue;
    end
    
    if ( TIMER.duration_met('aq_fixation') && ~looked_to_target )
      log_exit( cstate, is_debug );
      errors.initial_fixation_not_acquired = true;
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
      PROGRESS.(cstate) = TIMER.get_time( 'task' );
      sflip( opts );
      drew_cs = false;
      TIMER.reset_timers( cstate );
      TIMER.reset_timers( 'aq_cs' );
      cs_stim.reset_targets();
      first_entry = false;
    end
    
    if ( ~drew_cs )
      cs_reward_stim.draw();
      cs_stim.draw();
      sflip( opts );
      drew_cs = true;
    end
    
    if ( TIMER.duration_met('aq_cs') && ~looked_to_target )
      log_exit( cstate, is_debug );
      errors.cs_fixation_not_acquired = true;
      cstate = 'cs_error';
      first_entry = true;
      continue;
    end
    
    if ( cs_stim.in_bounds() )
      looked_to_target = true;
      PROGRESS.cs_target_acquire = TIMER.get_time( 'task' );
    elseif ( looked_to_target )
      log_exit( cstate, is_debug );
      errors.broke_cs_fixation = true;
      cstate = 'cs_error';
      first_entry = true;
      continue;
    end
    
    if ( cs_stim.duration_met() )
      log_exit( cstate, is_debug );
      cstate = 'cs_delay';
      first_entry = true;
      continue;
    end
    
    if ( TIMER.duration_met(cstate) )
      log_exit( cstate, is_debug );
      errors.cs_fixation_not_acquired = true;
      cstate = 'cs_error';
      first_entry = true;
    end
  end
  
  %   CS_DELAY
  if ( strcmp(cstate, 'cs_delay') )
    if ( first_entry )
      log_entry( cstate, is_debug );
      PROGRESS.(cstate) = TIMER.get_time( 'task' );
      TIMER.reset_timers( cstate );
      first_entry = false;
    end
    
    if ( STRUCTURE.require_fixation_during_delay )
      if ( ~cs_stim.in_bounds() )
        log_exit( cstate, is_debug );
        errors.broke_cs_fixation = true;
        cstate = 'cs_error';
        first_entry = true;
        continue;
      end
    end
    
    if ( TIMER.duration_met(cstate) )
      log_exit( cstate, is_debug );
      cstate = 'cs_reward';
      first_entry = true;
    end
  end
  
  %   CS_REWARD
  if ( strcmp(cstate, 'cs_reward') )
    if ( first_entry )
      log_entry( cstate, is_debug );
      PROGRESS.(cstate) = TIMER.get_time( 'task' );
      TIMER.reset_timers( cstate );
      TIMER.set_durations( 'cs_reward_pulse', REWARDS.single_pulse );
      delivered_pulses = 0;
      first_entry = false;
    end
    
    if ( delivered_pulses == 0 || TIMER.duration_met('cs_reward_pulse') )
      if ( delivered_pulses == current_n_rewards )
        log_exit( cstate, is_debug );
        cstate = 'iti';
        first_entry = true;
        continue;
      end
      log_debug( 'CS_Reward!', is_debug );
      image_index = current_n_rewards - delivered_pulses - 1;
      delivered_pulses = delivered_pulses + 1;
      if ( numel(IMAGES.reward_size) < delivered_pulses )
        log_debug( 'Not enough images.', is_debug );
        image_index = min( delivered_pulses, numel(IMAGES.reward_size) );
      end
      comm.reward( 1, REWARDS.single_pulse * 1e3 ); % ms
      TIMER.reset_timers( 'cs_reward_pulse' );
      if ( image_index > 0 )
        cs_reward_stim.image = IMAGES.reward_size(image_index).image;
        cs_reward_stim.draw();
      end
      cs_stim.draw();
      sflip( opts );
    end
  end
  
  %   ITI
  if ( strcmp(cstate, 'iti') )
    if ( first_entry )
      sflip( opts );
      log_entry( cstate, is_debug );
      PROGRESS.(cstate) = TIMER.get_time( 'task' );
      TIMER.reset_timers( cstate );
      first_entry = false;
    end
    
    if ( TIMER.duration_met(cstate) )
      log_exit( cstate, is_debug );
      cstate = 'new_trial';
      first_entry = true;
    end
  end
  
  %   FIXATION_ERROR
  if ( strcmp(cstate, 'fixation_error') )
    if ( first_entry )
      sflip( opts );
      log_entry( cstate, is_debug );
      PROGRESS.(cstate) = TIMER.get_time( 'task' );
      TIMER.reset_timers( cstate );
      first_entry = false;
    end
    
    if ( TIMER.duration_met(cstate) )
      log_exit( cstate, is_debug );
      cstate = 'new_trial';
      first_entry = true;
    end
  end
  
  %   CS_ERROR
  if ( strcmp(cstate, 'cs_error') )
    if ( first_entry )
      sflip( opts );
      log_entry( cstate, is_debug );
      PROGRESS.(cstate) = TIMER.get_time( 'task' );
      TIMER.reset_timers( cstate );
      first_entry = false;
    end
    
    if ( TIMER.duration_met(cstate) )
      log_exit( cstate, is_debug );
      cstate = 'new_trial';
      first_entry = true;
    end
  end

  [key_pressed, ~, key_code] = KbCheck();

  if ( key_pressed )
    if ( key_code(INTERFACE.stop_key) ), break; end
    
    if ( key_code(INTERFACE.reward_key) )
      if ( isnan(reward_key_timer) || toc(reward_key_timer) > reward_timeout )
        comm.reward( 1, REWARDS.key_press * 1e3 ); % ms
        reward_key_timer = tic();
      end
    end
  end

end

TRACKER.shutdown();

if ( opts.INTERFACE.save_data )
  data_dir = opts.PATHS.data_folder;
  data_file = get_filename( data_dir );
  data = struct();
  data.sync = PLEX_SYNC;
  data.opts = opts;
  data.DATA = DATA;
  save( fullfile(data_dir, data_file), 'data' );
end

end

function out = get_filename(dir)

mats = shared_utils.io.dirnames( dir, '.mat', false );

if ( numel(mats) == 0 )
  new_n = 1;
else
  is_cs_plus = cellfun( @(x) ~isempty(strfind(x, 'cs_plus__')), mats );
  n = numel( 'cs_plus__' );
  ns = cellfun( @(x) str2double(x(n+1:end-4)), mats(is_cs_plus) );
  new_n = max( ns ) + 1;
end

out = sprintf( 'cs_plus__%d', new_n );

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
	