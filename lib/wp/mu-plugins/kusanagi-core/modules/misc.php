<?php
if ( ! defined( 'ABSPATH' ) ) exit;

class KUSANAGI_Misc {

	private $default = array(
		'performance-viewer' => array( 'enable' => 1, 'capability' => 'manage_options' ),
		'opt-wp-settings'    => array( 'enable' => 0 ),
		'image_optimizer'  => array(
			'enable_image_optimize' => 0,
			'jpeg_quality'          => 82,
			'max_image_width'       => 1280,
			'error_mes'             => false,
			'png_min_quality'       => 60,
		),
	);
	private $performance_threshold = array(
		'timer' => array( 0.5, 0.7 ),
		'query' => array( 50, 100 ),
	);
	private $replace_tpl;
	public  $settings = array();
	private $warnings = array();
	private $mogrify  = false;
	private $jpegtran = false;
	private $pngquant = false;
	private $optipng  = false;

	public function __construct() {
		$this->replace_tpl       = plugin_dir_path( dirname( __FILE__ ) ) . 'advanced_cache_tpl/replace-class.tpl';
		
		add_action( 'admin_bar_menu'       , array( $this, 'performance_information' ), 9999 );
		add_action( 'wp_enqueue_scripts'   , array( $this, 'enqueue' ) );
		add_action( 'admin_enqueue_scripts', array( $this, 'enqueue' ) );
		add_action( 'admin_init'           , array( $this, 'add_tab' ) );
		add_action( 'init'                 , array( $this, 'compile_wp_settings_and_modify_wp_config' ) );
		add_action( 'all_admin_notices'    , array( $this, 'display_warnings' ) );
		add_action( 'admin_init'           , array( $this, 'optimizer_tools_check' ) );
		add_filter( 'wp_handle_upload'     , array( $this, 'fullsize_image_limiter' ) );
		add_filter( 'jpeg_quality'         , array( $this, 'jpeg_quality' ) );
		add_filter( 'image_make_intermediate_size', array( $this, 'optimize_intermediate_size' ) );
		
		$this->settings['performance-viewer'] = get_option( 'kusanagi-performance-viewer', $this->default['performance-viewer'] );
		$this->settings['opt-wp-settings']    = get_option( 'kusanagi-opt-wp-settings', $this->default['opt-wp-settings'] );
		$optimizer_settings = get_option( 'kusanagi-image-optimizer-settings', array() );
		if ( is_array( $optimizer_settings ) ) {
			$this->settings['image_optimizer'] = array_merge( $this->default['image_optimizer'], $optimizer_settings );
		} else {
			$this->settings['image_optimizer'] = $this->default['image_optimizer'];
		}
	}


	public function add_tab() {
		global $WP_KUSANAGI;
		$WP_KUSANAGI->add_tab( 'misc', __( 'Misc.', 'wp-kusanagi' ) );
	}


	public function enqueue() {
		global $WP_KUSANAGI;
		if ( is_admin_bar_showing() ) {
			wp_enqueue_style( 'kusanagi-admin-bar', plugin_dir_url( dirname( __FILE__ ) ) . 'css/kusanagi-admin-bar.css', array(), $WP_KUSANAGI->version );
		}
		if ( isset( $_GET['tab'] ) && 'misc' == $_GET['tab'] ) {
			wp_enqueue_script( 'image-optimizer', WP_CONTENT_URL . '/mu-plugins/kusanagi-core/js/image-optimizer.js', array( 'jquery-ui-slider' ), $WP_KUSANAGI->version );
			wp_enqueue_style( 'jquery-ui', WP_CONTENT_URL . '/mu-plugins/kusanagi-core/css/jquey-ui-slider.css', array(), $WP_KUSANAGI->version );
		}
	}

	public function performance_information( $wp_admin_bar ) {
		if ( ! current_user_can( $this->settings['performance-viewer']['capability'] ) || ! $this->settings['performance-viewer']['enable'] ) { return; }
		$timer = timer_stop();
		$queries = get_num_queries();

		if ( $timer > $this->performance_threshold['timer'][1] || $queries > $this->performance_threshold['query'][1] ) {
			$class = 'bad';
		} elseif ( $timer > $this->performance_threshold['timer'][0] || $queries > $this->performance_threshold['query'][0] ) {
			$class = 'attention';
		} else {
			$class = 'good';
		}

		$wp_admin_bar->add_menu(array(
			'id'     => 'wp-performances',
			'parent' => 'top-secondary',
			'meta'   => array( 'class' => $class ),
			'title'  => '<span class="ab-icon"></span><span class="ab-label">' . esc_html( $timer ) . ' sec. ' . esc_html( $queries ) . " queries.</span>\n",
			'href'   => false,
		));
	}


	public function compile_wp_settings_and_modify_wp_config() {
		global $wp_version, $kusanagi_optimized_version;
		if ( defined( 'WP_CLI' ) && constant( 'WP_CLI' ) === true ) {
			return;
		}
		if ( ! isset( $this->settings['opt-wp-settings']['enable'] ) || ! $this->settings['opt-wp-settings']['enable'] ) {
			return;
		}

		$wp_settings_path = ABSPATH . 'wp-settings.php';
		$optimized_wp_settings_path = ABSPATH . 'optimized_wp_settings.php';

		if ( is_file( $optimized_wp_settings_path ) ) {
			if ( $wp_version === $kusanagi_optimized_version ) {
				return;
			}
			if ( ! is_writable( $optimized_wp_settings_path ) ) {
				$this->warnings[] = '更新ができないコンパイル済みのwp-settings.php(optimized_wp_settings.php)があります。利用中のWordPressのバージョンと相違しており、不具合を起こす可能性がありますので、httpdユーザーでの書き込みができるようファイルの権限を変更してください。';
			}
		} elseif ( ! is_writable( ABSPATH ) ) {
				$this->warnings[] = 'コンパイルしたwp-settings.php(optimized_wp_settings.php)を保存できません。' . ABSPATH . ' にhttpdユーザーが書き込みできるようにディレクトリの権限を変更してください。';
				return;
		}

		$wp_includes = ABSPATH . 'wp-includes';
		if ( file_exists( ABSPATH . 'wp-config.php' ) ) {
			$wp_config_path = ABSPATH . 'wp-config.php';
		} elseif ( file_exists( dirname( ABSPATH ) . '/wp-config.php' ) ) {
			$wp_config_path = dirname( ABSPATH ) . '/wp-config.php';
		} else {
			$wp_config_path = false;
		}

		$settings_content = file_get_contents( $wp_settings_path );
		$settings_content = preg_replace( '#/\*\*[\s]+.*?[\s]+\*/#s', '', $settings_content );
		$settings_content = preg_replace( '#^[\s]*//.*$#m', '', $settings_content );
		$settings_content = preg_split( '#\n#', $settings_content );
		$files = array();
		$opt_settings = array();

		foreach( $settings_content as $line_num => $line ) {
			if ( preg_match( '#^[\s]*$#', $line ) ) {
				continue;
			}
			if ( preg_match( "#require(_once)? ABSPATH . WPINC . '(.*\.php)'#", $line, $m ) ) {
				$file = $wp_includes . $m[2];
				$str = file_get_contents( $file );
				$str = preg_replace( '#^<\?php\s*#', '', $str );
				$test = preg_replace( '#^/\*\*.*?^ \*/$#ms', '', $str );

				$inc      = true;
				$replaces = array();
				if ( '/version.php' === $m[2] ) {
					$inc = false;
				}
				if ( preg_match( '#__(DIR|FILE)__#', $test ) ) {
					$inc = false;
					$replaces = array(
						'/([\s\(.]+)__DIR__([\s\)\.]+)/m'  => '$1' . "'" . dirname( $file ) . "'" . '$2',
						'/([\s\(.]+)__FILE__([\s\)\.]+)/m' => '$1' . "'" . $file . "'" . '$2',
					);
				}

				$test = preg_replace( '#^(public |private |final |protected )?(function|class).*?^}$#ms', '', $test );
				if ( preg_match( '#return\s*;#', $test ) ) {
					$inc = false;
				}

				if ( false === $inc ) {
					$opt_settings[] = $line;
				} else {
					$opt_settings[] = '###' . $line;
					$str = php_strip_whitespace( $file );
					if ( $replaces ) {
						$str = preg_replace( array_keys( $replaces ), $replaces, $str );
					}
					$str = preg_replace( '#^<\?php\s*#', '', $str );
					$opt_settings[] = $str;
				}
			} else {
				$opt_settings[] = $line;
				if ( 0 === $line_num ) {
					$opt_settings[] = "\$kusanagi_optimized_version = '" . $wp_version . "';";
				}
			}
		}
		$opt_settings = implode( "\n", $opt_settings );
		$written = file_put_contents( $optimized_wp_settings_path, $opt_settings );

		if ( $written ) {
			chmod( $optimized_wp_settings_path, 0664 );
			if ( $wp_config_path ) {
				if ( ! is_writable( $wp_config_path ) ) {
					$this->warnings[] = 'wp-config.phpの書き込み権限がありません。httpdユーザーが書き込みできるようにwp-config.phpの権限を変更してください。';
					return;
				}
				$wp_config = file_get_contents( $wp_config_path );
				$wp_config = preg_split( '#\n#', $wp_config );
				$modified_config = array();
				$modify = true;
				foreach ( $wp_config as $line ) {
					if ( preg_match( "/^[\s]*if[\s]*\([\s]*file_exists\([\s]*ABSPATH[\s]*\.[\s]*'optimized_wp_settings.php'[\s]*\)/", $line ) ) {
						$modify = false;
					}
					if ( preg_match( "/^[\s]*require_once[\s]*\([\s]*ABSPATH[\s]*\.[\s]*'wp-settings.php'[\s]*\)[\s]*;/", $line ) && $modify ) {
						$modified_config[] = "if ( file_exists( ABSPATH . 'optimized_wp_settings.php' ) && ( ! defined( 'WP_CLI' ) || constant( 'WP_CLI' ) !== true ) ) {";
						$modified_config[] = "\trequire_once(ABSPATH . 'optimized_wp_settings.php');";
						$modified_config[] = "} else {";
						$modified_config[] = "\t" . $line;
						$modified_config[] = '}';
					} else {
						$modified_config[] = $line;
					}
				}
				if ( $modify ) {
					file_put_contents( $wp_config_path, implode( "\n", $modified_config ) );
				}
			}
		} else{
			$this->warnings[] = 'コンパイルしたwp-settings.php(optimized_wp_settings.php)の書き込みに失敗しました。';
		}
	}

	public function display_warnings() {
		if ( ! $this->warnings ) {
			return;
		}
?>
		<div class="error">
			<?php foreach ( $this->warnings as $warning ) : ?>
			<p><?php esc_html_e( $warning ); ?></p>
			<?php endforeach; ?>
		</div>
<?php
	}

	/**
	 * Check tools.
	 *
	 * @return void
	 */
	public function optimizer_tools_check() {

		exec( 'mogrify --version 2>&1', $mogrify_ver );
		if ( isset($mogrify_ver[0]) && strpos( $mogrify_ver[0], 'Version: ImageMagick' ) !== false ) {
			$this->mogrify = true;
		}
		if ( is_dir( '/opt/kusanagi/bin' ) ) {
			exec( '/opt/kusanagi/bin/jpegtran -version 2>&1', $jpegtran_ver );
		} else {
			exec( 'jpegtran -version 2>&1', $jpegtran_ver );
		}
		if ( isset($jpegtran_ver[0]) && strpos( $jpegtran_ver[0], 'mozjpeg version' ) !== false ) {
			$this->jpegtran = true;
		}
		exec( 'pngquant -V 2>&1', $pngquant_ver );
		if ( isset($pngquant_ver[0]) && version_compare( substr( $pngquant_ver[0], 0, 5 ), '2.0.0' ) > 0 ) {
			$this->pngquant = true;
		}
		exec( 'optipng -v 2>&1', $optipng_ver );
		if ( isset($optipng_ver[0]) && strpos( $optipng_ver[0], 'OptiPNG version' ) !== false ) {
			$this->optipng = true;
		}
	}

	/**
	 * Optimize full size image.
	 *
	 * @param  array $file_info The File info.
	 * @return array The File info.
	 */
	public function fullsize_image_limiter( $file_info ) {
		if ( 0 == $this->settings['image_optimizer']['enable_image_optimize'] ) {
			return $file_info;
		}

		if ( strpos( $file_info['type'], 'image/' ) === 0 ) {
			// $this->optimizer_tools_check();
			$size = getimagesize( $file_info['file'] );
			if ( $size ) {
				$file = $file_info['file'];
				if ( $size[0] > $this->settings['image_optimizer']['max_image_width'] ) {
					if ( $this->mogrify ) {

						$resize =  "-resize '" . $this->settings['image_optimizer']['max_image_width'] . "x9999>'";
						$quality = '';
						if ( $file_info['type'] == 'image/jpeg' && 1 == $this->settings['image_optimizer']['enable_image_optimize'] && isset( $this->settings['image_optimizer']['jpeg_quality'] ) ) {
							$quality = "-quality " . $this->settings['image_optimizer']['jpeg_quality'];
						}
						exec( "mogrify $resize $quality $file" );
						$stat = stat( dirname( $file ) );
						$perms = $stat['mode'] & 0000666; //same permissions as parent folder, strip off the executable bits
						@ chmod( $file, $perms );
					} else {

						$editor = wp_get_image_editor( $file_info['file'] );

						if ( ! is_wp_error( $editor ) && ! is_wp_error( $editor->resize( $this->settings['image_optimizer']['max_image_width'], 9999 ) ) ) {
							$image = wp_load_image( $file_info['file'] );
							$filename = basename( $file_info['file'] );
							$dest_path = dirname( $file_info['file'] );
							$tmp_name = $dest_path . '/temp-' . $filename;
							$resized_file = $editor->save( $tmp_name );

							if ( filesize( $tmp_name ) < filesize( $file_info['file'] ) ) {
								$stat = stat( dirname( $tmp_name ) );
								$perms = $stat['mode'] & 0000666; //same permissions as parent folder, strip off the executable bits
								@ chmod( $tmp_name, $perms );
								@ rename( $tmp_name, $file_info['file'] );
							} else {
								@ unlink( $tmp_name );
							}
						}
					}
				}
				if ( $file_info['type'] === 'image/jpeg' ) {
					$this->optimize_jpeg( $file );
				} elseif ( $file_info['type'] === 'image/png' ) {
					$this->optimize_png( $file );
				}
			}
		}
		return $file_info;
	}

	/**
	 * Optimizer intermediate size image.
	 *
	 * @param  string $filename The File Path.
	 * @return string           The File Path.
	 */
	public function optimize_intermediate_size( $filename ) {

		if ( 0 == $this->settings['image_optimizer']['enable_image_optimize'] ) {
			return $filename;
		}

		$ftype = wp_check_filetype( $filename, wp_get_mime_types() );

		if ( $ftype['type'] === 'image/jpeg' ) {
			$this->optimize_jpeg( $filename );
		} elseif ( $ftype['type'] === 'image/png' ) {
			$this->optimize_png( $filename );
		}

		return $filename;
	}

	/**
	 * [jpeg_quality description]
	 * @param  [type] $jpeg_quality [description]
	 * @return [type]               [description]
	 */
	public function jpeg_quality( $jpeg_quality ) {
		if ( 1 == $this->settings['image_optimizer']['enable_image_optimize'] && isset( $this->settings['image_optimizer']['jpeg_quality'] ) ) {
			$jpeg_quality = $this->settings['image_optimizer']['jpeg_quality'];
		}
		return $jpeg_quality;
	}

	/**
	 * Optimize jpeg image.
	 *
	 * @param  string $file File Path.
	 * @return void
	 */
	private function optimize_jpeg( $file ) {
		if ( $this->jpegtran ) {
			if ( is_dir( '/opt/kusanagi/bin' ) ) {
				exec( "/opt/kusanagi/bin/jpegtran -copy none -optimize -outfile $file $file" );
			} else {
				exec( "jpegtran -copy none -optimize -outfile $file $file" );
			}
		}
	}

	/**
	 * Optimize png image.
	 *
	 * @param  string $file File Path.
	 * @return void
	 */
	private function optimize_png( $file ) {

		$png_min_quality = $this->settings['image_optimizer']['png_min_quality'];
		if ( $this->pngquant ) {
			exec( "pngquant --quality=$png_min_quality- --skip-if-larger --ext=.png --force $file" );
		}
		if ( $this->optipng ) {
			exec( "optipng --preserve $file" );
		}
		$stat = stat( dirname( $file ) );
		$perms = $stat['mode'] & 0000666; //same permissions as parent folder, strip off the executable bits
		@ chmod( $file, $perms );
	}

	public function save_options() {
		global $WP_KUSANAGI;
		
		$post_data = wp_unslash( $_POST );
		if ( isset( $_POST['kusanagi-performance-viewer'] ) ) {
			$caps = get_role( 'administrator' );
			$data = array();
			$data['enable'] = preg_match( '/^[0-1]{1}$/', $post_data['kusanagi-performance-viewer']['enable'] ) ? $post_data['kusanagi-performance-viewer']['enable'] : $this->settings['performance-viewer']['enable'];
			$data['capability'] = in_array( $post_data['kusanagi-performance-viewer']['capability'], $caps->capabilities ) ? $post_data['kusanagi-performance-viewer']['capability'] : $this->settings['performance-viewer']['capability'];
			$ret = update_option( 'kusanagi-performance-viewer', $data );
		}
		if ( isset( $_POST['opt-wp-settings'] ) ) {
			$data = array();
			$data['enable'] = preg_match( '/^[0-1]{1}$/', $post_data['opt-wp-settings']['enable'] ) ? $post_data['opt-wp-settings']['enable'] : $this->settings['opt-wp-settings']['enable'];
			$ret2 = update_option( 'kusanagi-opt-wp-settings', $data );
		}
		$life_time = get_option( 'site_cache_life', array( 'home' => 60, 'archive' => 60, 'singular' => 360, 'exclude' => '', 'allowed_query_keys' => '', 'update' => 'none', 'replaces' => array(), 'replace_login' => 0 ) );

		if ( isset( $_POST['site_cache_life'] ) && is_array( $_POST['site_cache_life'] ) ) {
			if ( is_array( $post_data['site_cache_life']['replaces'] ) ) {
				$replaces = array();
				foreach ( $post_data['site_cache_life']['replaces'] as $num => $values ) {
					$values = array_map( 'trim', $values );
					if ( $values['target'] && $values['replace'] ) {
						$replaces[] = $values;
					}
				}
				$minutes = $replaces;
			} else {
				$minutes = array();
			}
			$life_time['replaces'] = $minutes;
			$life_time['replace_login'] = (boolean)$post_data['site_cache_life']['replace_login'];
			
			$ret3 = update_option( 'site_cache_life', $life_time );
			if ( $ret3 ) {
				// replace class.phpの再生成
				$WP_KUSANAGI->modules['page-cache']->generate_replace_class_file();
			}
		}

		if ( isset( $_POST['image_optimizer'] ) && is_array( $_POST['image_optimizer'] ) ) {
			$settings = array();
			foreach ( $this->default['image_optimizer'] as $key => $def ) {
				switch ( $key ) {
				case 'enable_image_optimize' :
					if ( ! isset( $post_data['image_optimizer'][$key] ) || ! is_numeric( $post_data['image_optimizer'][$key] ) ) {
						$settings[$key] = $this->settings['image_optimizer'][$key];
					} else {
						$settings[$key] = (bool)$post_data['image_optimizer'][$key];
					}
					break;
				case 'jpeg_quality' :
					if ( ! isset( $post_data['image_optimizer'][$key] ) || ! is_numeric( $post_data['image_optimizer'][$key] ) || 0 > $post_data['image_optimizer'][$key] || 100 < $post_data['image_optimizer'][$key] ) {
						$settings[$key] = $this->settings['image_optimizer'][$key];
					} else {
						$settings[$key] = $post_data['image_optimizer'][$key];
					}
					break;
				case 'max_image_width' :
					if ( ! isset( $post_data['image_optimizer'][$key] ) || ! is_numeric( $post_data['image_optimizer'][$key] ) || 320 > $post_data['image_optimizer'][$key] ) {
						$settings[$key] = $this->settings['image_optimizer'][$key];
					} else {
						$settings[$key] = $post_data['image_optimizer'][$key];
					}
					break;
				default :
				}
			}
			$this->settings['image_optimizer'] = $settings;
			$ret4 = update_option( 'kusanagi-image-optimizer-settings', $settings );
		}

		if ( $ret || $ret2 || $ret3 || $ret4 ) {
			$WP_KUSANAGI->messages[] = __( 'Update settings successfully.', 'wp-kusanagi' );
			wp_cache_delete ( 'alloptions', 'options' );
			$this->settings['performance-viewer'] = get_option( 'kusanagi-performance-viewer', $this->default['performance-viewer'] );
			$this->settings['opt-wp-settings']    = get_option( 'kusanagi-opt-wp-settings', $this->default['opt-wp-settings'] );
		}
	}
} // class end.
$this->modules['misc'] = new KUSANAGI_Misc;
