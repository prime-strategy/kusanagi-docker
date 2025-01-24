<?php
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * WordPress 自動アップデートモジュール
 */
class KUSANAGI_Automatic_Updates {

	private $option_key          = 'kusanagi-auto-updates-settings';
	private $option_schedule_key = 'kusanagi-auto-updates-schedule-settings';
	private $errors              = array();
	private $some_enable         = '';
	private $defaults            = array();
	private $keys                = array();
	public $settings             = array();
	public $schedule_settings    = array();

	public $schedules = array();

	public $schedule_hooks = array();

	public $next_schedule_time = 0;

	/**
	 * Construct the KUSANAGI_Automatic_Updates.
	 */
	public function __construct() {

		$this->defaults = array(
			'translation' => 'enable',
			'plugin'      => 'disable',
			'theme'       => 'disable',
			'core'        => 'minor',
		);
		$this->keys     = array_keys( $this->defaults );

		$this->settings = wp_parse_args( get_option( $this->option_key, array() ), $this->defaults );

		$this->some_enable = false;

		foreach ( $this->settings as $type => $status ) {
			$this->add_autoupdate_filter( $type, $status );
			if ( ! $this->some_enable && 'disable' !== $status ) {
				$this->some_enable = true;
			}
		}
		$this->schedules         = array(
			'schedule' => 'disable',
			'week_day' => array(),
			'hour'     => 0,
			'min'      => 0,
		);
		$this->schedule_settings = wp_parse_args( get_option( $this->option_schedule_key, array() ), $this->schedules );
		$this->schedule_hooks    = array(
			'wp_version_check',
			'wp_update_plugins',
			'wp_update_themes',
			'wp_maybe_auto_update',
		);

		if ( 'enable' === $this->schedule_settings['schedule'] && $this->schedule_settings['week_day'] ) {
			$this->next_schedule_time = $this->get_next_schedule_time();
			add_action( 'schedule_event', array( $this, 'schedule_auto_update_event' ) );
		}

		add_action( 'admin_init', array( $this, 'add_tab' ) );
		add_action( 'pre_auto_update', array( $this, 'preload_wp_filesystem' ), 10, 3 );
	}

	/**
	 * Determines automatic updates.
	 * @param string $type The type of update item: 'core', 'theme',
	 *                        'plugin', 'translation'.
	 * @param string $status The update item status: 'enable', 'disable', 'minor'.
	 */
	private function add_autoupdate_filter( $type, $status ) {

		if ( ! in_array( $status, $this->defaults, true ) ) {
			return;
		}

		if ( ! in_array( $type, $this->keys, true ) ) {
			return;
		}

		if ( 'disable' === $status ) {
			add_filter( 'auto_update_' . $type, '__return_false' );
		} elseif ( 'enable' === $status ) {
			if ( 'core' === $type ) {
				add_filter( 'allow_dev_auto_core_updates', '__return_false' );
				add_filter( 'allow_minor_auto_core_updates', '__return_true' );
				add_filter( 'allow_major_auto_core_updates', '__return_true' );
			} else {
				add_filter( 'auto_update_' . $type, '__return_true' );
			}
		} elseif ( 'minor' === $status ) {
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
	public function schedule_auto_update_event( $event ) {
		if ( in_array( $event->hook, $this->schedule_hooks, true ) ) {
			if ( false !== $event->schedule ) {
				$event->schedule = false;
			}
			$event->timestamp = $this->next_schedule_time;
			$event->interval  = 0;
		}

		return $event;
	}

	/**
	 * Get next schedule timestamp.
	 *
	 * @return int Return next schedule Unix timestamp.
	 */
	private function get_next_schedule_time() {

		$current_time = time();
		$current_w    = gmdate( 'w', $current_time );
		$datetime     = "{$this->schedule_settings['hour']}:{$this->schedule_settings['min']}:00";

		$week_day_runtime = array();
		foreach ( $this->schedule_settings['week_day'] as $week_day ) {
			$w         = str_replace( 'week_day_', '', $week_day );
			$next_days = 0;
			if ( $current_w > $w ) {
				$next_days = 7 - abs( $current_w - $w );
			} elseif ( $current_w < $w ) {
				$next_days = $w - $current_w;
			}
			$week_day_runtime[] = get_gmt_from_date( gmdate( 'Y-m-d', $current_time + $next_days * DAY_IN_SECONDS ) . ' ' . $datetime, 'U' );
		}
		sort( $week_day_runtime );

		foreach ( $week_day_runtime as $run_time ) {
			if ( $run_time > $current_time ) {
				return $run_time;
			}
		}

		return 0;
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

		// phpcs:ignore WordPress.Security.NonceVerification.Missing
		$post_data = wp_unslash( $_POST );

		$this->some_enable = false;
		foreach ( $this->defaults as $key => $status ) {
			if ( isset( $post_data[ $key ] ) && $post_data[ $key ] ) {
				$status = sanitize_text_field( $post_data[ $key ] );
			}
			if ( ! $this->some_enable && 'disable' !== $status ) {
				$this->some_enable = true;
			}
			$this->settings[ $key ] = $status;
		}
		$ret = update_option( $this->option_key, $this->settings );

		foreach ( $this->schedules as $key => $value ) {
			if ( isset( $post_data[ $key ] ) ) {
				$value = $post_data[ $key ];
			}
			$this->schedule_settings[ $key ] = $value;
		}
		$schedule_ret = update_option( $this->option_schedule_key, $this->schedule_settings );
		$this->clear_auto_update_cron();

		if ( $ret && $schedule_ret ) {
			$WP_KUSANAGI->messages[] = __( 'Update settings successfully.', 'wp-kusanagi' );
		}
	}

	/**
	 * Clear core, theme, plugin cron update.
	 *
	 * @return void
	 */
	private function clear_auto_update_cron() {
		foreach ( $this->schedule_hooks as $schedule_hook ) {
			wp_clear_scheduled_hook( $schedule_hook );
		}
	}

	/**
	 * Check autoupdate status.
	 *
	 * @return void
	 */
	private function check_disabled_auto_update() {

		if ( ! class_exists( 'WP_Automatic_Updater' ) ) {
			include_once ABSPATH . 'wp-admin/includes/class-wp-upgrader.php';
		}

		$upgrader = new WP_Automatic_Updater();
		if ( $upgrader->is_disabled() ) {
			if ( defined( 'DISALLOW_FILE_MODS' ) && DISALLOW_FILE_MODS ) {
				/* translators: 1: the definition. */
				$this->errors[] = sprintf( __( 'Background updates are disabled. Change to define %1$s or comment out the definition.', 'wp-kusanagi' ), "<code>('DISALLOW_FILE_MODS', false);</code>" );
			}

			if ( wp_installing() ) {
				$this->errors[] = __( 'WP is installing', 'wp-kusanagi' );
			}

			if ( defined( 'AUTOMATIC_UPDATER_DISABLED' ) && AUTOMATIC_UPDATER_DISABLED ) {
				$this->errors[] = __( 'Automatic update is disabled. The constant AUTOMATIC_UPDATER_DISABLED is set.', 'wp-kusanagi' );
			}

			if ( empty( $this->errors ) ) {
				$this->errors[] = __( 'Automatic update is disabled. The "automatic_updater_disabled" filter is set.', 'wp-kusanagi' );
			}
		}

		if ( defined( 'DISABLE_WP_CRON' ) && DISABLE_WP_CRON ) {
			$this->errors[] = __( 'Automatic updates are disabled. The "DISABLE_WP_CRON" constant is set.', 'wp-kusanagi' );
		}
	}

	/**
	 * Check FTP connection setting.
	 *
	 * @return void.
	 */
	private function check_ftp_constant() {

		if ( ! defined( 'FS_METHOD' ) ) {
			/* translators: %s: defined constant. */
			$this->errors[] = sprintf( __( 'Add %s to the wp-config.php file.', 'wp-kusanagi' ), "<code>define('FS_METHOD', 'ftpext');</code>" );
		}

		if ( ! defined( 'FTP_HOST' ) ) {
			/* translators: %s: defined constant. */
			$this->errors[] = sprintf( __( 'Add %s to the wp-config.php file.', 'wp-kusanagi' ), "<code>define('FTP_HOST', 'ftp.example.com');</code>" );
		}

		if ( ! defined( 'FTP_USER' ) ) {
			/* translators: %s: defined constant. */
			$this->errors[] = sprintf( __( 'Add %s to the wp-config.php file.', 'wp-kusanagi' ), "<code>define('FTP_USER', 'kusanagi');</code>" );
		}

		if ( ! defined( 'FTP_PASS' ) ) {
			/* translators: 1: defined constant, 2: login password. */
			$this->errors[] = sprintf( __( 'Add %1$s to the wp-config.php file and change %2$s part to login password.', 'wp-kusanagi' ), "<code>define('FTP_PASS', '*****');</code>", '<code>*****</code>' );
		}
	}

	/**
	 * Check File System
	 */
	public function check_filesystem() {
		$this->check_disabled_auto_update();
		$this->check_ftp_constant();

		if ( ! $this->errors ) {
			ob_start();
			$credentials = request_filesystem_credentials( site_url( 'wp-admin' ), '', false, false, array() );
			ob_clean();

			if ( $credentials && ! WP_Filesystem( $credentials, ABSPATH, false ) ) {
				/* translators: %s: credential hostname. */
				$this->errors[] = sprintf( __( 'Failed to connect to FTP Server %s. If you do not remember your credentials, you should contact your web host.', 'wp-kusanagi' ), $credentials['hostname'] );
			}
		}
	}

	/**
	 * アップデート有効性チェック
	 *
	 * @return void
	 */
	public function check_update_errors() {
		if ( $this->some_enable ) {
			$this->check_filesystem();
		}
	}

	/**
	 * Getter the update list
	 *
	 * @return array This update list.
	 */
	public function get_update_list() {
		$update_lists = array();

		$theme              = wp_get_theme();
		$auto_update_themes = (array) get_site_option( 'auto_update_themes', array() );
		$theme_updates      = get_site_transient( 'update_themes' );
		$update_lists[]     = $this->get_theme_update_data( $theme, $auto_update_themes, $theme_updates );
		$parent             = $theme->parent();
		if ( $parent ) {
			$update_lists[] = $this->get_theme_update_data( $parent, $auto_update_themes, $theme_updates );
		}

		$plugins             = get_plugins();
		$auto_update_plugins = (array) get_site_option( 'auto_update_plugins', array() );
		$plugin_updates      = get_site_transient( 'update_plugins' );
		foreach ( $plugins as $path => $plugin ) {
			if ( is_plugin_active( $path ) ) {
				if ( 'enable' === $this->settings['plugin'] ) {
					$enabled = true;
				} elseif ( 'disable' === $this->settings['plugin'] ) {
					$enabled = false;
				} else {
					$enabled = in_array( $path, $auto_update_plugins, true );
				}
				$update_lists[] = array(
					'name'       => $plugin['Name'],
					'type'       => 'Plugin',
					'autoupdate' => array(
						'enabled'   => $enabled,
						'supported' => ( isset( $plugin_updates->response[ $path ] ) || isset( $plugin_updates->no_update[ $path ] ) ),
					),
				);
			}
		}

		return $update_lists;
	}

	/**
	 * テーマのアップデート有効性
	 *
	 * @param WP_Theme $theme
	 * @param array $auto_update_themes
	 * @param array $theme_updates
	 * @return array update data
	 */
	public function get_theme_update_data( $theme, $auto_update_themes = array(), $theme_updates = array() ) {
		if ( $auto_update_themes ) {
			$auto_update_themes = (array) get_site_option( 'auto_update_themes', array() );
		}
		if ( empty( $theme_updates ) ) {
			$theme_updates = get_site_transient( 'update_themes' );
		}
		$stylesheet = $theme->get_stylesheet();
		if ( 'enable' === $this->settings['theme'] ) {
			$enabled = true;
		} elseif ( 'disable' === $this->settings['theme'] ) {
			$enabled = false;
		} else {
			$enabled = in_array( $stylesheet, $auto_update_themes, true );
		}
		$data = array(
			'name'       => $theme->get( 'Name' ),
			'type'       => 'Theme',
			'autoupdate' => array(
				'enabled'   => $enabled,
				'supported' => ( isset( $theme_updates->response[ $stylesheet ] ) || isset( $theme_updates->no_update[ $stylesheet ] ) ),
			),
		);

		return $data;
	}

	/**
	 * Getter the error messages
	 *
	 * @return array This error messages.
	 */
	public function get_errors() {
		return $this->errors;
	}

	/**
	 * wp_filesystemをプリロードする
	 *
	 * @param string $type
	 * @param object $item
	 * @param string $context
	 * @return void
	 */
	public function preload_wp_filesystem( $type, $item, $context ) {
		global $wp_version, $wp_filesystem;

		// WordPress 6.6 より前の環境では問題ないのでスキップ
		if ( version_compare( $wp_version, '6.6', '<' ) ) {
			return;
		}

		if ( ! $wp_filesystem ) {
			if ( ! function_exists( 'WP_Filesystem' ) ) {
				require_once ABSPATH . 'wp-admin/includes/file.php';
			}
			ob_start();
			$credentials = request_filesystem_credentials( '' );
			ob_end_clean();
			if ( false !== $credentials ) {
				WP_Filesystem( $credentials );
			}
		}
	}
}

$this->modules['automatic-updates'] = new KUSANAGI_Automatic_Updates();
