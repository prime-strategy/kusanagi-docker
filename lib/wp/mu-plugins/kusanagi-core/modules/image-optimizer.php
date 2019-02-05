<?php
if ( ! defined( 'ABSPATH' ) ) exit;

class KUSANAGI_Image_Optimizer {

	public  $settings;
	private $default;
	private $mogrify = false;
	private $jpegtran = false;
	private $pngquant = false;
	private $optipng = false;

	public function __construct() {
		$this->settings = get_option( 'kusanagi-image-optimizer-settings', array() );

		if ( defined( 'WP_INSTALLING' ) && WP_INSTALLING && ! is_array( $this->settings ) ) { return; }
		$this->default = array(
			'enable_image_optimize' => 0,
			'jpeg_quality'          => 82,
			'max_image_width'       => 1280,
			'error_mes'             => false,
		);

		$this->settings = array_merge( $this->default, $this->settings );
		add_action( 'admin_init'           , array( $this, 'add_tab' ) );
		add_action( 'admin_init'           , array( $this, 'optimizer_tools_check' ) );
		add_filter( 'wp_handle_upload'     , array( $this, 'fullsize_image_limiter' ) );
		add_filter( 'jpeg_quality'         , array( $this, 'jpeg_quality' ) );
		add_filter( 'image_make_intermediate_size', array( $this, 'optimize_intermediate_size' ) );
		if ( isset( $_GET['tab'] ) && 'image-optimizer' == $_GET['tab'] ) {
			add_action( 'admin_enqueue_scripts', array( $this, 'enqueue' ) );
		}
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
		exec( 'jpegtran -version 2>&1', $jpegtran_ver );
		if ( isset($jpegtran_ver[0]) && strpos( $jpegtran_ver[0], 'mozjpeg version' ) !== false ) {
			$this->jpegtran = true;
		}
		exec( 'pngquant -V 2>&1', $pngquant_ver );
		if ( isset($pngquant_ver[0]) && version_compare( substr( $pngquant_ver[0], 0, 5 ), '2.0.0' ) ) {
			$this->pngquant = true;
		}
		exec( 'optipng -v 2>&1', $optipng_ver );
		if ( isset($optipng_ver[0]) && strpos( $optipng_ver[0], 'OptiPNG version' ) !== false ) {
			$this->optipng = true;
		}
	}

	/**
	 * Add tab menu
	 */
	public function add_tab() {
		global $WP_KUSANAGI;
		$WP_KUSANAGI->add_tab( 'image-optimizer', __( 'Image Optimizer', 'wp-kusanagi' ) );
	}

	/**
	 * Enqueue javascript and stylesheet.
	 * @return void
	 */
	public function enqueue() {
		global $WP_KUSANAGI;
		wp_enqueue_script( 'image-optimizer', WP_CONTENT_URL . '/mu-plugins/kusanagi-core/js/image-optimizer.js', array( 'jquery-ui-slider' ), $WP_KUSANAGI->version );
		wp_enqueue_style( 'jquery-ui', WP_CONTENT_URL . '/mu-plugins/kusanagi-core/css/jquey-ui-slider.css', array(), $WP_KUSANAGI->version );
	}

	/**
	 * Save current moudles setting data.
	 * @return void
	 */
	public function save_options() {
		global $WP_KUSANAGI;

		$post_data = wp_unslash( $_POST );
		$settings = array();
		foreach ( $this->default as $key => $def ) {
			switch ( $key ) {
			case 'enable_image_optimize' :
				if ( ! isset( $post_data[$key] ) || ! is_numeric( $post_data[$key] ) ) {
					$settings[$key] = $this->settings[$key];
				} else {
					$settings[$key] = (bool)$post_data[$key];
				}
				break;
			case 'jpeg_quality' :
				if ( ! isset( $post_data[$key] ) || ! is_numeric( $post_data[$key] ) || 0 > $post_data[$key] || 100 < $post_data[$key] ) {
					$settings[$key] = $this->settings[$key];
				} else {
					$settings[$key] = $post_data[$key];
				}
				break;
			case 'max_image_width' :
				if ( ! isset( $post_data[$key] ) || ! is_numeric( $post_data[$key] ) || 320 > $post_data[$key] ) {
					$settings[$key] = $this->settings[$key];
				} else {
					$settings[$key] = $post_data[$key];
				}
				break;
			default :
			}
		}
		$this->settings = $settings;

		$ret = update_option( 'kusanagi-image-optimizer-settings', $settings );

		if ( $ret ) {
			$WP_KUSANAGI->messages[] = __( 'Update settings successfully.', 'wp-kusanagi' );
		}
	}

	/**
	 * Optimize full size image.
	 *
	 * @param  array $file_info The File info.
	 * @return array The File info.
	 */
	public function fullsize_image_limiter( $file_info ) {
		if ( 0 == $this->settings['enable_image_optimize'] ) {
			return $file_info;
		}

		if ( strpos( $file_info['type'], 'image/' ) === 0 ) {
			// $this->optimizer_tools_check();
			$size = getimagesize( $file_info['file'] );
			if ( $size ) {
				$file = $file_info['file'];
				if ( $size[0] > $this->settings['max_image_width'] ) {
					if ( $this->mogrify ) {

						$resize =  "-resize '" . $this->settings['max_image_width'] . "x9999>'";
						$quality = '';
						if ( $file_info['type'] == 'image/jpeg' && 1 == $this->settings['enable_image_optimize'] && isset( $this->settings['jpeg_quality'] ) ) {
							$quality = "-quality " . $this->settings['jpeg_quality'];
						}
						exec( "mogrify $resize $quality $file" );
						$stat = stat( dirname( $file ) );
						$perms = $stat['mode'] & 0000666; //same permissions as parent folder, strip off the executable bits
						@ chmod( $file, $perms );
					} else {

						$editor = wp_get_image_editor( $file_info['file'] );

						if ( ! is_wp_error( $editor ) && ! is_wp_error( $editor->resize( $this->settings['max_image_width'], 9999 ) ) ) {
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

		if ( 0 == $this->settings['enable_image_optimize'] ) {
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
		if ( 1 == $this->settings['enable_image_optimize'] && isset( $this->settings['jpeg_quality'] ) ) {
			$jpeg_quality = $this->settings['jpeg_quality'];
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
			exec( "jpegtran -copy none -optimize -outfile $file $file" );
		}
	}

	/**
	 * Optimize png image.
	 *
	 * @param  string $file File Path.
	 * @return void
	 */
	private function optimize_png( $file ) {

		if ( $this->pngquant ) {
			exec( "pngquant --skip-if-larger --ext=.png --force $file" );
		}
		if ( $this->optipng ) {
			exec( "optipng --preserve $file" );
		}
		$stat = stat( dirname( $file ) );
		$perms = $stat['mode'] & 0000666; //same permissions as parent folder, strip off the executable bits
		@ chmod( $file, $perms );
	}

} // class end
$this->modules['image-optimizer'] = new KUSANAGI_Image_Optimizer;
