<?php
if ( ! defined( 'ABSPATH' ) ) exit;

class KUSANAGI_Security_Check {

	private $messages = array();
	private $wp_config_path = '';

	public function __construct() {
		add_action( 'plugins_loaded'            , array( $this, 'load_text' )                               , 99 );
		add_action( 'wp_dashboard_setup'        , array( $this, 'kusanagi_security_information_widgets' )   , 0  );
	}

	public function load_text() {
		$this->messages = array(
			'wp_config_locate' => array(
				0   => __( 'wp-config.php is in the correct directory.', 'wp-kusanagi' ),
				1   => __( 'wp-config.php exist in the public folder. Please move wp-config.php to DocumentRoot and improve security.', 'wp-kusanagi' ),
				2   => __( 'WordPress installed the sub-directory. You can improve security by including wp-config.php.', 'wp-kusanagi' ),
				999 => __( 'wp-config.php not found.', 'wp-kusanagi' ),
			),
			'wp_config_permission' => array(
				0   => __( 'wp-config.php permission is %1s.', 'wp-kusanagi' ),
				1   => __( 'wp-config.php permission is %1s. Recommend permission is 440.', 'wp-kusanagi' ),
				2   => __( 'Administrator of wp-config.php is %1s.%2s.', 'wp-kusanagi' ),
				3   => __( 'Administrator of wp-config.php is %1s.%2s. Recommend administrator is kusanagi.www.', 'wp-kusanagi' ),
				999 => __( 'wp-config.php not found.', 'wp-kusanagi' ),
			),
			'uploads_htaccess' => array(
				0   => __( '%1s.htaccess permission is %2s.', 'wp-kusanagi' ),
				1   => __( '%1s.htaccess permission is %2s. Recommend permission is 644.', 'wp-kusanagi' ),
				2   => __( 'Administrator of %1s.htaccess is %2s.%3s.', 'wp-kusanagi' ),
				3   => __( 'Administrator of %1s.htaccess is %2s.%3s. Recommend administrator is kusanagi.kusanagi.', 'wp-kusanagi' ),
				999 => __( 'Move configuration file .htaccess to %1s.', 'wp-kusanagi' ),
			),
			'wp_content_dir' => array(
				0   => __( 'wp-content/ permission is %1s.', 'wp-kusanagi' ),
				1   => __( 'wp-content/ permission is %1s. Recommend permission is 755.', 'wp-kusanagi' ),
				2   => __( 'Administrator of wp-content/ is %1s.%2s.', 'wp-kusanagi' ),
				3   => __( 'Administrator of wp-content/ is %1s.%2s. Recommend administrator is kusanagi.kusanagi.', 'wp-kusanagi' ),
				999 => __( 'wp-content/ not found.', 'wp-kusanagi' ),
			),
			'phpinfo' => array(
				0   => __( 'HHVM/%1s', 'wp-kusanagi' ),
				1   => __( 'PHP/%1s', 'wp-kusanagi' ),
			),
			'webserverinfo' => array(
				0   => __( 'Nginx/%1s', 'wp-kusanagi' ),
				1   => __( 'Apache/%1s', 'wp-kusanagi' ),
				999 => __( 'Web server information not found.', 'wp-kusanagi' ),
			),
		);
	}

	public function kusanagi_security_information_widgets() {
		wp_add_dashboard_widget( 'kusanagi-security-information', __('Current security setting', 'wp-kusanagi'), array( $this, 'kusanagi_security_information' ) );
	}


	public function kusanagi_security_information() {

?>
		<style>
			.kusanagi-security p{
				padding: 5px 5px 5px 10px;
				margin: 3px;
			}
			.kusanagi-security p.alter {
				background-color: #ffdddd;
				border: solid 1px #ff3333;
				border-left-width: 5px;
			}
			.kusanagi-security p.ok{
				border: solid 1px #46b450;
				border-left-width: 5px;
			}
		</style>
		<div class="kusanagi-security">
			<p class="ok"><?php printf( __( 'PHP status : %1s', 'wp-kusanagi' ), $this->get_phpinfo() ); ?></p>
			<p class="ok"><?php printf( __( 'Web server : %1s', 'wp-kusanagi' ), $this->get_webserverinfo() ); ?></p>
			<?php echo $this->check_locate_wp_config(); ?>
			<?php echo $this->check_permission_wp_config(); ?>
			<?php if ( $this->server_software === 'apache' ) echo $this->check_uploads_htaccess(); ?>
			<?php echo $this->check_wp_content_dir(); ?>
		</div>
		<?php
	}

	private function check_locate_wp_config() {

		$message = '';
		if ( isset($_SERVER['DOCUMENT_ROOT']) && $_SERVER['DOCUMENT_ROOT'] == untrailingslashit( ABSPATH ) ) {
			if ( file_exists( ABSPATH . 'wp-config.php' ) ) {
				$this->wp_config_path = ABSPATH . 'wp-config.php';
				$message .= '<p class="alter">'.$this->get_message( 'wp_config_locate', 1 ).'</p>';
			} elseif( file_exists( dirname( ABSPATH  ) . '/wp-config.php' ) ) {
				$this->wp_config_path = dirname( ABSPATH  ) . '/wp-config.php';
				$message .= '<p class="ok">'.$this->get_message( 'wp_config_locate', 0 ).'</p>';
			}
		} else {
			if ( file_exists( ABSPATH . 'wp-config.php' ) ) {
				$this->wp_config_path = ABSPATH . 'wp-config.php';
				$message .= '<p class="alter">'.$this->get_message( 'wp_config_locate', 2 ).'</p>';
			} elseif( file_exists( dirname( ABSPATH  ) . '/wp-config.php' ) ) {
				$this->wp_config_path = dirname( ABSPATH  ) . '/wp-config.php';
				$message .= '<p class="alter">'.$this->get_message( 'wp_config_locate', 2 ).'</p>';
			}
		}

		if ( !$this->wp_config_path ) {
			$message .= '<p class="alter">'.$this->get_message( 'wp_config_locate', 999 ).'</p>';
		}

		return $message;
	}

	private function check_permission_wp_config() {
		$path = false;
		$message = '';

		if ( !$this->wp_config_path ) {
			return false;
		}

		$message = '';
		$file_info = $this->get_file_info( $this->wp_config_path );
		if ( '440' === $file_info['permission'] ) {
			$message .= '<p class="ok">'.sprintf( $this->get_message( 'wp_config_permission', 0 ), $file_info['permission'] ).'</p>';
		} else {
			$message .= '<p class="alter">'.sprintf( $this->get_message( 'wp_config_permission', 1 ), $file_info['permission'] ).'</p>';
		}
		if ( 'www' === $file_info['group'] && 'kusanagi' === $file_info['owner'] ) {
			$message .= '<p class="ok">'.sprintf( $this->get_message( 'wp_config_permission', 2 ), $file_info['owner'], $file_info['group'] ).'</p>';
		} else {
			$message .= '<p class="alter">'.sprintf( $this->get_message( 'wp_config_permission', 3 ), $file_info['owner'], $file_info['group'] ).'</p>';
		}

		return $message;
	}

	private function check_uploads_htaccess() {

		$upload_dir = wp_upload_dir();
		$filename = $upload_dir['basedir']. '/.htaccess';
		$message = '';
		if ( file_exists( $filename ) ) {
			$upload_base_dir = str_replace( ABSPATH , '', $upload_dir['basedir']).'/';
			$file_info = $this->get_file_info( $filename );
			if ( '644' === $file_info['permission'] ) {
				$message .= '<p class="ok">'.sprintf( $this->get_message( 'uploads_htaccess', 0 ), $upload_base_dir, $file_info['permission'] ).'</p>';
			} else {
				$message .= '<p class="alter">'.sprintf( $this->get_message( 'uploads_htaccess', 1 ), $upload_base_dir, $file_info['permission'] ).'</p>';
			}
			if ( 'kusanagi' === $file_info['group'] && 'kusanagi' === $file_info['owner'] ) {
				$message .= '<p class="ok">'.sprintf( $this->get_message( 'uploads_htaccess', 2 ), $upload_base_dir, $file_info['owner'], $file_info['group'] ).'</p>';
			} else {
				$message .= '<p class="alter">'.sprintf( $this->get_message( 'uploads_htaccess', 3 ), $upload_base_dir, $file_info['owner'], $file_info['group'] ).'</p>';
			}
		} else {
			$upload_base_dir = str_replace( ABSPATH , '', $upload_dir['basedir']).'/';
			$message .= '<p class="alter">'.sprintf( $this->get_message( 'uploads_htaccess', 999 ), $upload_base_dir ).'</p>';
		}

		return $message;
	}

	private function check_wp_content_dir() {

		$message = '';
		if ( file_exists( WP_CONTENT_DIR ) ) {
			$file_info = $this->get_file_info( WP_CONTENT_DIR );
			if ( '755' === $file_info['permission'] ) {
				$message .= '<p class="ok">'.sprintf( $this->get_message( 'wp_content_dir', 0 ), $file_info['permission'] ).'</p>';
			} else {
				$message .= '<p class="alter">'.sprintf( $this->get_message( 'wp_content_dir', 1 ), $file_info['permission'] ).'</p>';
			}
			if ( 'kusanagi' === $file_info['group'] && 'kusanagi' === $file_info['owner'] ) {
				$message .= '<p class="ok">'.sprintf( $this->get_message( 'wp_content_dir', 2 ), $file_info['group'], $file_info['owner'] ).'</p>';
			} else {
				$message .= '<p class="alter">'.sprintf( $this->get_message( 'wp_content_dir', 3 ), $file_info['group'], $file_info['owner'] ).'</p>';
			}
		}

		return $message;
	}

	/**
	 * PHP実行環境情報出力
	 *
	 * @return [type] [description]
	 */
	private function get_phpinfo() {
		if ( defined( 'HHVM_VERSION' ) ) {
			return sprintf( $this->get_message( 'phpinfo', 0 ), HHVM_VERSION );
		} else {
			return sprintf( $this->get_message( 'phpinfo', 1 ), phpversion() );
		}
	}

	/**
	 * WEBサーバー情報出力
	 * @return [type] [description]
	 */
	private function get_webserverinfo() {
		$this->server_software = '';
		$server_software = isset($_SERVER['SERVER_SOFTWARE']) ? strtolower($_SERVER['SERVER_SOFTWARE']) : '';
		if ( $server_software && false !== strpos( $server_software, 'nginx' ) ) {
			$this->server_software = 'nginx';
			return sprintf( $this->get_message( 'webserverinfo', 0 ), str_replace( 'nginx/', '', $server_software ) );
		} elseif ( $server_software && false !== strpos( $server_software, 'apache' ) ) {
			$this->server_software = 'apache';
			if ( preg_match( '|Apache/([\d\.]*?) |', @shell_exec( '/usr/sbin/httpd -v 2>&1' ), $version ) ) {
				return sprintf( $this->get_message( 'webserverinfo', 1 ), $version[1] );
			} else {
				return sprintf( $this->get_message( 'webserverinfo', 1 ), __( 'Failed to get version information.', 'wp-kusanagi' ) );;
			}
		} else {
			return $this->get_message( 'webserverinfo', 999 );
		}
	}

	private function get_file_info( $path ) {

		if ( ! file_exists( $path ) ) {
			return false;
		}

		$file_info = array( 'permission' => '', 'group' => '', 'owner' => '' );
		$file_info['permission'] = substr( sprintf( '%o', fileperms( $path ) ), -3 );

		$file_group = posix_getgrgid( filegroup( $path ) );
		$file_owner = posix_getpwuid( fileowner( $path ) );
		$file_info['group'] = $file_group['name'];
		$file_info['owner'] = $file_owner['name'];

		return $file_info;
	}

	private function get_message( $section, $code ) {
		$ret = false;
		if ( isset( $this->messages[$section][$code] ) ) {
			$ret = $this->messages[$section][$code];
		}
		return $ret;
	}
}
new KUSANAGI_Security_Check;
