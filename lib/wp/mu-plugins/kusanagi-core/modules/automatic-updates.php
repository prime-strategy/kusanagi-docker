<?php
if ( ! defined( 'ABSPATH' ) ) exit; 
/**
 * WordPress 自動アップデートモジュール
 */
class KUSANAGI_Automatic_Updates {

	private $option_key = 'kusanagi-auto-updates-settings';
	private $option_schedule_key = 'kusanagi-auto-updates-schedule-settings';
	private $errors = array();
	private $some_enable = '';
	private $defaults  = array();
	private $keys = array();
	public  $settings = array();
	public  $schedule_settings = array();

	/**
	 * Construct the KUSANAGI_Automatic_Updates.
	 */
	public function __construct() {

		$this->defaults = array(
			'translation' => 'enable',
			'plugin' => 'disable',
			'theme'  => 'disable',
			'core'   => 'minor',
		);
		$this->keys = array_keys( $this->defaults );

		$this->settings = wp_parse_args( get_option( $this->option_key, array() ), $this->defaults );

		$this->some_enable = false;

		foreach ( $this->settings as $type => $status ) {
			$this->add_autoupdate_filter( $type, $status );
			if ( !$this->some_enable && 'disable' != $status ) {
				$this->some_enable = true;
			}
		}
		$this->schedules = array(
			'schedule' => 'disable',
			'week_day' => array(),
			'hour' => 0,
			'min' => 0,
		);
		$this->schedule_settings =  wp_parse_args( get_option( $this->option_schedule_key, array() ), $this->schedules );
		$this->schedule_hooks = array( 'wp_version_check', 'wp_update_plugins', 'wp_update_themes', 'wp_maybe_auto_update' );

		if ( 'enable' == $this->schedule_settings['schedule'] && $this->schedule_settings['week_day'] ) {
			$this->next_schedule_time = $this->get_next_schedule_time();
			add_action( 'schedule_event', array( $this, 'schedule_autoupdate_event' ) );
		}

		add_action( 'admin_init'               , array( $this, 'add_tab' ) );
	}

	/**
	 * Determines automatic updates.
	 * @param string $type The type of update item: 'core', 'theme',
	 *                        'plugin', 'translation'.
	 * @param string $status The update item status: 'enable', 'disable', 'minor'.
	 */
	private function add_autoupdate_filter( $type, $status ) {

		if ( ! in_array( $status, $this->defaults ) ) {
			return;
		}

		if ( ! in_array( $type, $this->keys ) ) {
			return;
		}

		if ( 'disable' == $status ) {
			add_filter( 'auto_update_'.$type, '__return_false' );
		} elseif ( 'enable' == $status ) {
			if ( 'core' == $type ) {
				add_filter( 'allow_dev_auto_core_updates', '__return_false' );
				add_filter( 'allow_minor_auto_core_updates', '__return_true' );
				add_filter( 'allow_major_auto_core_updates', '__return_true' );
			} else {
				add_filter( 'auto_update_'.$type, '__return_true' );
			}
		} elseif ( 'minor' == $status ) {
			add_filter( 'allow_dev_auto_core_updates', '__return_false' );
			add_filter( 'allow_minor_auto_core_updates', '__return_true' );
			add_filter( 'allow_major_auto_core_updates', '__return_false' );
		}
	}

	/**
	 * Change core, theme, plugin update cron type and time.
	 * @param stdClass $event {
	 *     An object containing an event's data.
	 *
	 *     @type string       $hook      Action hook to execute when event is run.
	 *     @type int          $timestamp Unix timestamp (UTC) for when to run the event.
	 *     @type string|false $schedule  How often the event should recur. See `wp_get_schedules()`.
	 *     @type array        $args      Arguments to pass to the hook's callback function.
	 * }
	 * @return stdClass       The event's data.
	 */
	public function schedule_autoupdate_event( $event ) {
		if ( in_array( $event->hook, $this->schedule_hooks ) ) {
			if ( $event->schedule != false ) {
				$event->schedule = false;
			}
			$event->timestamp = $this->next_schedule_time;
			$event->interval = 0;
		}
		return $event;
	}

	/**
	 * Get next schedule timestamp.
	 *
	 * @return int Return next schedule Unix timestamp.
	 */
	private function get_next_schedule_time() {

		$current_time = current_time( 'timestamp', 1 );
		$current_date = date( 'Y-m-d', $current_time );
		$current_w = date( 'w', $current_time );
		$datetime = "{$this->schedule_settings['hour']}:{$this->schedule_settings['min']}:00";

		$next = false;
		$week_day_runtime = array();
		foreach ( $this->schedule_settings['week_day'] as $week_day ) {
			$w = str_replace( 'week_day_', '', $week_day );
			$next_days = 0;
			if ( $current_w > $w ) {
				$next_days = 7 - abs($current_w -$w);
			} elseif ( $current_w < $w ) {
				$next_days = $w - $current_w;
			}
			$week_day_runtime[] = get_gmt_from_date( date( 'Y-m-d', $current_time + $next_days * DAY_IN_SECONDS ) . ' ' . $datetime, 'U' );
		}
		sort($week_day_runtime);

		foreach ( $week_day_runtime as $run_time ) {
			if ( $run_time > $current_time ) {
				return $run_time;
			}
		}
	}

	/**
	 * Add automatic updates tab.
	 */
	public function add_tab() {
		global $WP_KUSANAGI;
		$WP_KUSANAGI->add_tab( 'automatic-updates', __( 'Automatic Updates', 'wp-kusanagi' ) );
	}

	/**
	 * Save the automatic update settings.
	 *
	 * @return [type] [description]
	 */
	public function save_options() {
		global $WP_KUSANAGI;

		$post_data = wp_unslash( $_POST );

		$this->some_enable = false;
		foreach ( $this->defaults as $key => $status ) {
			if ( isset($post_data[$key]) && in_array( $post_data[$key], $this->defaults ) ) {
				$status = $post_data[$key];
			}
			if ( !$this->some_enable && 'disable' != $status ) {
				$this->some_enable = true;
			}
			$this->settings[$key] = $status;
		}
		$ret = update_option( $this->option_key, $this->settings );

		foreach ( $this->schedules as $key => $value ) {
			if ( isset($post_data[$key]) ) {
				$value = $post_data[$key];
			}
			$this->schedule_settings[$key] = $value;
		}
		$schedule_ret = update_option( $this->option_schedule_key, $this->schedule_settings );
		$this->clear_autoupdate_cron();

		if ( $ret && $schedule_ret ) {
			$WP_KUSANAGI->messages[] = __( 'Update settings successfully.', 'wp-kusanagi' );
		}
	}

	/**
	 * Clear core, theme, plugin cron update.
	 *
	 * @return void
	 */
	private function clear_autoupdate_cron() {
		foreach ( $this->schedule_hooks as $schedule_hook ) {
			wp_clear_scheduled_hook($schedule_hook);
		}
	}

	/**
	 * Check autoupdate status.
	 *
	 * @return void
	 */
	private function check_disabled_auto_update() {

		remove_all_filters( 'automatic_updater_disabled' );
		add_filter( 'automatic_updater_disabled', '__return_false', 999 );

		if ( !class_exists( 'WP_Automatic_Updater' ) ) {
			include_once( ABSPATH . 'wp-admin/includes/class-wp-upgrader.php' );
		}

		$upgrader = new WP_Automatic_Updater();
		if ( $upgrader->is_disabled() ) {
			if ( defined( 'DISALLOW_FILE_MODS' ) && DISALLOW_FILE_MODS ) {
				$this->errors[] = __( "Background updates are disabled. Change to define <code>('DISALLOW_FILE_MODS', false);</code> or comment out the definition.", 'wp-kusanagi');
			}

			if ( wp_installing() ) {
				$this->errors[] = __( "WP is installing", 'wp-kusanagi');
			}
		}
	}

	/**
	 * Check FTP connection setting.
	 *
	 * @return void.
	 */
	private function check_ftp_connection() {

		$method = 'ftpsockets';
		if ( !defined( 'FS_METHOD' ) ) {
			$this->errors[] = sprintf( __( "Add <code>define('FS_METHOD', '%1s');</code> to the wp-config.php file.", 'wp-kusanagi') , $method );
		}

		if ( !defined( 'FTP_HOST' ) ) {
			$this->errors[] = __( "Add <code>define('FTP_HOST', 'Localhost');</code> to the wp-config.php file.", 'wp-kusanagi');
		}

		if ( !defined( 'FTP_USER' ) ) {
			$this->errors[] = __( "Add <code>define('FTP_USER', 'kusanagi');</code> to the wp-config.php file.", 'wp-kusanagi');
		}

		if ( !defined( 'FTP_PASS' ) ) {
			$this->errors[] = __( "Add <code>define('FTP_PASS', '*****');</code> to the wp-config.php file and change <code>*****</code> part to login password.", 'wp-kusanagi');
		}
	}

	/**
	 * Check File System
	 */
	public function check_filesystem() {

		if ( $this->some_enable ) {

			$this->check_disabled_auto_update();
			$this->check_ftp_connection();

			if ( !$this->errors ) {
				ob_start();
				$credentials = request_filesystem_credentials( site_url('wp-admin'), '', false, false, array() );
				ob_clean();

				if ( $credentials && ! WP_Filesystem( $credentials, ABSPATH, false )) {
					$this->errors[] = sprintf(  __( 'Failed to connect to FTP Server %s. If you do not remember your credentials, you should contact your web host.', 'wp-kusanagi' ), $credentials['hostname'] );
				}
			}
		}
	}

	/**
	 * Getter the error messages
	 *
	 * @return array() This error messages.
	 */
	public function get_errors() {
		return $this->errors;
	}
}
$this->modules['automatic-updates'] = new KUSANAGI_Automatic_Updates;
