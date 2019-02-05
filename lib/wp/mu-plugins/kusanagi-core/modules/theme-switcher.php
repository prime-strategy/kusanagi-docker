<?php
if ( ! defined( 'ABSPATH' ) ) exit;

class KUSANAGI_Theme_Switcher {

	private $device_theme = false;
	private $current_group = false;
	public  $avaiable_themes;

	private $device_table;
	private $group_table;
	private $relation_table;

	function __construct() {
		global $wpdb;

		$this->device_table = $wpdb->prefix . 'sitemanager_device';
		$this->group_table = $wpdb->prefix . 'sitemanager_device_group';
		$this->relation_table = $wpdb->prefix . 'sitemanager_device_relation';
		if ( defined( 'WP_INSTALLING' ) && WP_INSTALLING ) {
			add_action( 'wp_install'        , array( $this, 'do_activation_module_hook' ) );
		} else {
			if ( ! get_option( 'theme_switcher_disable', 0 ) ) {
				add_action( 'plugins_loaded'    , array( $this, 'get_avaiable_themes' ), 9 );
			}
			add_action( 'wpmu_new_blog'     , array( $this, 'do_ms_activation_module_hook' ) );

			if ( ! is_admin() && ! get_option( 'theme_switcher_disable', 0 ) && isset( $_SERVER['HTTP_USER_AGENT'] ) && isset( $_SERVER['DOCUMENT_ROOT'] ) ) {
				add_action( 'plugins_loaded', array( $this, 'switch_theme' ) );
				add_filter( 'wp_headers'    , array( $this, 'add_vary_header' ) );
			}
			add_action( 'admin_init'        , array( $this, 'add_tab' ) );
			add_action( 'admin_init'        , array( $this, 'add_updated_messages' ) );
		}
	}


	public function add_tab() {
		global $WP_KUSANAGI;
		$WP_KUSANAGI->add_tab( 'theme-switcher', __( 'Device Theme Switcher', 'wp-kusanagi' ) );
	}


	public function add_updated_messages() {
		global $WP_KUSANAGI;
		if ( isset( $_GET['action'] ) && isset( $_GET['result'] ) && in_array( $_GET['action'], array( 'edit_group', 'add_group', 'edit_device', 'add_device' ) ) && in_array( $_GET['result'], array( 'inserted', 'updated' ) ) ) {
			$WP_KUSANAGI->messages[] = __( 'Update settings successfully.', 'wp-kusanagi' );
		}
	}


	public function get_avaiable_themes() {
		// if ( false === ( $this->avaiable_themes = get_transient( 'avaiable_themes' ) ) ) {
			if ( function_exists( 'wp_get_themes' ) ) {
				$this->avaiable_themes =  wp_get_themes();
			} else {
				$this->avaiable_themes =  get_themes();
			}
			// set_transient( 'avaiable_themes', $this->avaiable_themes, 3600 * 24 );
		// }
	}


	public function save_options() {
		global $WP_KUSANAGI;

		if ( isset( $_GET['action'] ) ) {
			switch ( $_GET['action'] ) {
			case 'edit_group' :
			case 'add_group' :
				$this->update_device_group( $_GET['action'] );
				break;
			case 'edit_device' :
			case 'add_device' :
				$this->update_device( $_GET['action'] );
				break;
			default :
			}
		}
		if ( isset( $_POST['theme_switcher_disable'] ) ) {
			$ret = update_option( 'theme_switcher_disable', (int)$_POST['theme_switcher_disable'] );
			if ( $ret ) {
				do_action( 'theme_switcher/theme_switcher_disable' );
				$WP_KUSANAGI->messages[] = __( 'Update settings successfully.', 'wp-kusanagi' );
			}
		}
	}


	private function update_device_group( $action ) {
		global $wpdb;

		$post_data = stripslashes_deep( $_POST );
		$data = array();
		$redirect = '';
		$data['group_name'] = $post_data['group_name'];

		if ( ! isset( $post_data['theme'] ) || ( $post_data['theme'] && ! in_array( $post_data['theme'], array_keys( $this->avaiable_themes ) ) ) ) {
			$data['theme'] = '';
		} else {
			$data['theme'] = $post_data['theme'];
		}

		if ( function_exists( 'mb_convert_kana' ) ) {
			$data['slug'] = mb_convert_kana( $post_data['slug'], 'a' );
			$data['priority'] = mb_convert_kana( $post_data['priority'], 'n' );
		}

		$data['slug'] = preg_replace( '/[^\w_-]/', '', $data['slug'] );
		$data['slug'] = strtolower( $data['slug'] );
		$data['priority'] = preg_replace( '/[^\d]/', '', $data['priority'] );

		if ( ! (int)$data['priority'] ) {
			$data['priority'] = 0;
		}

		if ( ! $data['group_name'] || ! $data['slug'] ) { return; }

		if ( $action == 'edit_group' && isset( $_GET['group_id'] ) && $_GET['group_id'] ) {
			$data['builtin'] = $this->is_builtin_device_group( (int)$_GET['group_id'] ) ? 1 : 0;
		} else {
			$data['builtin'] = 0;
		}

		if ( $action == 'add_group' ) {
			$wpdb->insert( $this->group_table, $data, array( '%s', '%s', '%s', '%d' ) );
			$group_id = $wpdb->insert_id;
			if ( $group_id ) {
				$redirect = add_query_arg( array( 'action' => 'edit_group', 'group_id' => $group_id, 'result' => 'inserted' ) );
			}
		} elseif ( $action == 'edit_group' ) {
			$group_id = (int)$_GET['group_id'];
			$ret = $wpdb->update( $this->group_table, $data, array( 'group_id' => $group_id ), array( '%s', '%s', '%s', '%d' ), array( '%d' ) );
			if ( $ret ) {
				$redirect = add_query_arg( array( 'result' => 'updated' ) );
			}
		}

		$this->build_device_rules();

		if ( $redirect ) {
			do_action( 'theme_switcher/device_group_updated' );
			wp_redirect( $redirect );
			exit;
		} else {
			$redirect = remove_query_arg( array( 'result' ) );
			wp_redirect( $redirect );
			exit;
		}
	}


	private function update_device( $action ) {
		global $wpdb;

		$post_data = stripslashes_deep( $_POST );
		$data = array();
		$relation_data = array();
		$redirect = '';
		$tmp_redirect = '';

		if ( ! $post_data['device_name'] || ! $post_data['keyword'] ) { return; }

		$data['device_name'] = $post_data['device_name'];
		$data['keyword'] = $post_data['keyword'];
		if ( $action == 'edit_device' && isset( $_GET['device_id'] ) && $_GET['device_id'] ) {
			$data['builtin'] = $this->is_builtin_device( (int)$_GET['device_id'] ) ? 1 : 0;
		} else {
			$data['builtin'] = 0;
		}

		if ( isset( $post_data['device_group'] ) && is_array( $post_data['device_group'] ) ) {
			$relation_data = array_map( 'absint',  $post_data['device_group'] );
		}

		if ( $action == 'add_device' ) {
			$wpdb->insert( $this->device_table, $data, array( '%s', '%s', '%s', '%d', '%d' ) );
			$device_id = $wpdb->insert_id;
			$tmp_redirect = add_query_arg( array( 'action' => 'edit_device', 'device_id' => $device_id, 'result' => 'inserted' ) );
		} elseif ( $action == 'edit_device' ) {
			$device_id = (int)$_GET['device_id'];
			$ret = $wpdb->update( $this->device_table, $data, array( 'device_id' => $device_id ), array( '%s', '%s', '%s', '%d', '%d' ), array( '%d' ) );
			$tmp_redirect = add_query_arg( array( 'result' => 'updated' ) );
		}

		if ( $device_id ) {
			$groups = $this->get_device_relation_groups( $device_id );
			$group_ids = $this->filtering_by_property( $groups, 'group_id' );
			$deletes = array_diff( $group_ids, $relation_data );
			$inserts = array_diff( $relation_data, $group_ids );
			if ( ( $deletes || $inserts ) || ( 'add_device' == $action && $wpdb->insert_id ) || ( 'edit_device' == $action && $ret ) ) {
				$redirect = $tmp_redirect;
			}
			if ( ! empty( $deletes ) ) {
				$delete_ids = implode( ',', $deletes );
				$sql = "DELETE FROM `{$this->relation_table}` WHERE `device_id` = {$device_id} AND `group_id` IN ( {$delete_ids} )";
				$wpdb->query( $sql );
			}
			if ( ! empty( $inserts ) ) {
				foreach ( $inserts as $insert_id ) {
					$data = array( 'device_id' => $device_id, 'group_id' => $insert_id );
					$wpdb->insert( $this->relation_table, $data, array( '%d', '%d' ) );
				}
			}
		}
		$this->build_device_rules();

		if ( $redirect ) {
			do_action( 'theme_switcher/device_updated' );
			wp_redirect( $redirect );
			exit;
		} else {
			$redirect = remove_query_arg( array( 'result' ) );
			wp_redirect( $redirect );
			exit;
		}
	}


	private function build_device_rules() {
		$rules = array();
		$groups = $this->get_groups();
		if ( $groups ) {
			foreach ( $groups as $group ) {
				$devices = $this->get_group_relation_devices( $group->group_id );
				if ( $devices ) {
					$regex = array();
					$rules[$group->slug]['theme'] = $group->theme;
					foreach ( $devices as $device ) {
						$regex = str_replace( '/', '\/', $device->keyword );
						$rules[$group->slug]['regex'][] = $regex;
					}
				}
			}
		}
		update_option( 'sitemanager_device_rules', $rules );
	}

	private function is_builtin_device_group( $group_id ) {
		$group_id = (int)$group_id;
		$group = $this->get_group( $group_id );
		return (bool)$group->builtin;
	}

	private function is_builtin_device( $device_id ) {
		$device_id = (int)$device_id;
		$device = $this->get_device( $device_id );
		return (bool)$device->builtin;
	}


	public function do_ms_activation_module_hook( $blog_id ) {
		global $wpdb;
		switch_to_blog( $blog_id );
		$this->device_table = $wpdb->prefix . 'sitemanager_device';
		$this->group_table = $wpdb->prefix . 'sitemanager_device_group';
		$this->relation_table = $wpdb->prefix . 'sitemanager_device_relation';
		$this->do_activation_module_hook();
		restore_current_blog();
		$this->device_table = $wpdb->prefix . 'sitemanager_device';
		$this->group_table = $wpdb->prefix . 'sitemanager_device_group';
		$this->relation_table = $wpdb->prefix . 'sitemanager_device_relation';
	}


	public function do_activation_module_hook() {
		global $wpdb;
		require_once( ABSPATH . 'wp-admin/includes/upgrade.php' );

		$charset_collate = $wpdb->get_charset_collate();

		$sql = "SHOW TABLES FROM `{$wpdb->dbname}` LIKE '{$this->device_table}'";
		$table_exists = $wpdb->get_var( $sql );

		if ( ! $table_exists ) {
			$sql = "
CREATE TABLE `{$this->device_table}` (
	`device_id` bigint(20) NOT NULL auto_increment,
	`device_name` text NOT NULL,
	`keyword` text NOT NULL,
	`builtin` tinyint(1) NOT NULL default '0',
	PRIMARY KEY  (`device_id`)
) $charset_collate";
			dbDelta( $sql, true );

			$sql = "
INSERT INTO `{$this->device_table}` (`device_id`, `device_name`, `keyword`, `builtin`) VALUES
(1, 'iPad', '\\\(iPad', 0),
(2, 'iPhone', '\\\(iPhone', 0),
(3, 'iPod', '\\\(iPod', 0),
(4, 'Android', 'Android .+ Mobile', 0),
(5, 'Android Tablet', ' Android ', 0),
(6, 'IEMobile', 'IEMobile', 0),
(7, 'Windows Phone', 'Windows Phone', 0),
(8, 'Firefox Mobile', 'Android\; Mobile\; .+Firefox', 0),
(9, 'Firefox Tablet', 'Android\; Tablet\; .+Firefox', 0)";
			$wpdb->query( $sql );
		}

		$sql = "SHOW TABLES FROM `{$wpdb->dbname}` LIKE '{$this->group_table}'";
		$table_exists = $wpdb->get_var( $sql );

		if ( ! $table_exists ) {
			$sql = "
CREATE TABLE `{$this->group_table}` (
	`group_id` bigint(20) NOT NULL auto_increment,
	`group_name` text NOT NULL,
	`theme` text NOT NULL,
	`slug` tinytext NOT NULL,
	`priority` int(11) NOT NULL,
	`builtin` binary(1) NOT NULL default '0',
 	PRIMARY KEY (`group_id`)
) $charset_collate";
			dbDelta( $sql, true );

			$sql = "
INSERT INTO `{$this->group_table}` (`group_id`, `group_name`, `theme`, `slug`, `priority`, `builtin`) VALUES
(1, '" . __( 'Tablet', 'wp-kusanagi' ) . "', '', 'tablet', 200, '0'),
(2, '" . __( 'Smart Phone', 'wp-kusanagi' ) . "', '', 'smart', 100, '0')";
			$wpdb->query( $sql );
		}

		$sql = "SHOW TABLES FROM `{$wpdb->dbname}` LIKE '{$this->relation_table}'";
		$table_exists = $wpdb->get_var( $sql );

		if ( ! $table_exists ) {
			$sql = "
CREATE TABLE `{$this->relation_table}` (
	`group_id` bigint(20) NOT NULL,
	`device_id` bigint(20) NOT NULL,
	KEY `group_id` (`group_id`,`device_id`)
) $charset_collate";
			dbDelta( $sql, true );

			$sql = "
INSERT INTO `{$this->relation_table}` (`group_id`, `device_id`) VALUES
(1, 1),
(1, 5),
(2, 2),
(2, 3),
(2, 4),
(2, 6),
(2, 7),
(1, 9),
(2, 8)";
			$wpdb->query( $sql );
		}
		$this->build_device_rules();
	}



	public function switch_theme() {
		if ( $this->detect_device_template() !== false ) {
			add_filter( 'template'  , array( $this, 'switch_template' ) );
			add_filter( 'stylesheet', array( $this, 'switch_stylesheet' ) );
		}
	}


	private function detect_device_template() {
		$ua = $_SERVER['HTTP_USER_AGENT'];
		$path = preg_replace( '#^' . str_replace( '\\', '/', $_SERVER['DOCUMENT_ROOT'] ) . '#', '', str_replace( '\\', '/', ABSPATH ) );

		$regexes = get_option( 'sitemanager_device_rules', array() );

		$site_view = '';
		if ( isset( $_GET['site-view'] ) ) {
			$site_view = $_GET['site-view'];
		} elseif ( isset( $_COOKIE['site-view'] ) ) {
			$site_view = $_COOKIE['site-view'];
		}

		if ( $site_view ) {
			if ( strtolower( $site_view ) == 'pc' ) {
				setcookie( 'site-view', 'pc', 0, $path );
				$this->device_theme = false;
				return false;
			}
			foreach ( $regexes as $this->current_group => $arr ) {
				if ( strtolower( $site_view ) == strtolower( $this->current_group ) ) {
					setcookie( 'site-view', $this->current_group, 0, $path  );
					if ( ! in_array( $arr['theme'], array_keys( $this->avaiable_themes ) ) ) {
						return false;
					}
					$this->device_theme = $arr['theme'];
					return $this->current_group;
				}
			}
		}

		foreach ( $regexes as $this->current_group => $arr ) {
			$regex = '/' . implode( '|', $arr['regex'] ) . '/';
			if ( preg_match( $regex, $ua ) ) {
				if ( ! in_array( $arr['theme'], array_keys( $this->avaiable_themes ) ) ) {
					return false;
				}
				$this->device_theme = $arr['theme'];
				return $this->current_group;
			}
		}
		return false;
	}


	private function walker_preg_quote( $item, $delimiter = '/' ) {
		if ( is_array( $item ) ) {
			foreach ( $item as $key => $val ) {
				$item[$key] = $this->walker_preg_quote( $val, $delimiter );
			}
		} else {
			$item = preg_quote( $item, $delimiter );
		}
		return $item;
	}


	public function switch_template( $theme ) {
		return $this->filter_theme( $theme, true );
	}


	public function switch_stylesheet( $theme ) {
		return $this->filter_theme( $theme );
	}


	private function filter_theme( $theme, $template = false ) {
		if ( $this->device_theme ) {
			if ( $template ) {
				if ( function_exists( 'wp_get_theme' ) ) {
					$theme_data = wp_get_theme( $this->device_theme );
				} else {
					$theme_data = get_theme( $this->device_theme );
				}

				if ( is_object( $theme_data ) ) {
					$parent = $theme_data->__get( 'Template' );
				} else {
					$parent = $theme_data['Template'];
				}

				if ( $parent != $this->device_theme ) {
					$theme = $parent;
				} else {
					$theme = $this->device_theme;
				}
			} else {
				$theme = $this->device_theme;
			}
		}
		return $theme;
	}


	public function get_groups() {
		global $wpdb;
		$sql = "
SELECT	*
FROM	`{$this->group_table}`
ORDER BY	priority ASC
";
		$groups = $wpdb->get_results( $sql );
		return $groups;
	}


	public function get_devices() {
		global $wpdb;
		$sql = "
SELECT	*
FROM	`{$this->device_table}`
ORDER BY	device_name ASC
LIMIT	20";
		$groups = $wpdb->get_results( $sql );
		return $groups;
	}


	public function get_group( $group_id ) {
		global $wpdb;
		$group_id = (int)$group_id;
		$sql = "
SELECT	*
FROM	`{$this->group_table}`
WHERE	`group_id` = $group_id
LIMIT	1
";
		$group = $wpdb->get_row( $sql );
		return $group;
	}


	public function get_device( $device_id ) {
		global $wpdb;
		$device_id = (int)$device_id;
		$sql = "
SELECT	*
FROM	`{$this->device_table}`
WHERE	`device_id` = $device_id
LIMIT	1
";
		$group = $wpdb->get_row( $sql );
		return $group;
	}


	public function get_device_relation_groups( $device_id ) {
		global $wpdb;

		$device_id = (int)$device_id;
		$sql = "
SELECT	g.*
FROM	`{$this->device_table}` as d,
		`{$this->relation_table}` as r,
		`{$this->group_table}` as g
WHERE	d.device_id = r.device_id
AND		r.group_id = g.group_id
AND		d.device_id = {$device_id}
ORDER BY g.priority ASC
";
		$groups = $wpdb->get_results( $sql );
		return $groups;
	}


	public function get_group_relation_devices( $group_id ) {
		global $wpdb;

		$group_id = (int)$group_id;
		$sql = "
SELECT	d.*
FROM	`{$this->device_table}` as d,
		`{$this->relation_table}` as r,
		`{$this->group_table}` as g
WHERE	d.device_id = r.device_id
AND		r.group_id = g.group_id
AND		g.group_id = {$group_id}
ORDER BY d.device_id ASC
";
		$devices = $wpdb->get_results( $sql );
		return $devices;
	}


	public function filtering_by_property( $objects, $property ) {
		$return = array();
		if ( ! empty( $objects ) && is_array( $objects ) ) {
			foreach ( $objects as $object ) {
				if ( is_object( $object ) ) {
					$object = get_object_vars( $object );
				}
				if ( is_array( $object ) && isset( $object[$property] ) ) {
					$return[] = $object[$property];
				}
			}
		}
		return $return;
	}


	public function add_vary_header( $headers ) {
		if ( isset( $headers['Vary'] ) ) {
			$headers['Vary'] .= ',User-Agent';
		} else {
			$headers['Vary'] = 'User-Agent';
		}
		return $headers;
	}


	static function is_device( $slug ) {
		global $WP_KUSANAGI;
		return in_array( $WP_KUSANAGI->modules['theme-switcher']->current_group, (array)$slug );
	}

} // class end
$this->modules['theme-switcher'] = new KUSANAGI_Theme_Switcher;

if ( is_admin() && isset( $_GET['tab'] ) && $_GET['tab'] == 'theme-switcher' ) {
//return;
require_once( ABSPATH . 'wp-admin/includes/class-wp-list-table.php' );

class KUSANAGI_Device_Group_List_Table extends WP_List_Table {

	function __construct( $args = array() ) {
		$args = wp_parse_args( $args, array(
			'plural'   => '',
			'singular' => '',
			'ajax'     => false,
			'screen'   => null,
		) );

		$screen = get_current_screen();
		$this->screen = $screen;

		if ( ! $args['plural'] ) {
			$args['plural'] = $screen->base;
		}
		$this->_args = $args;
		$this->_column_headers = array(
			$this->get_columns(),
			array(),
			array(),
		);
	}

	function prepare_items() {
		global $WP_KUSANAGI;
		$this->items = $WP_KUSANAGI->modules['theme-switcher']->get_groups();
	}

	function get_columns() {
		$columns = array(
			'group_name' => __( 'Group Name', 'wp-kusanagi' ),
			'theme'      => __( 'Theme', 'wp-kusanagi' ),
			'slug'       => __( 'Slug', 'wp-kusanagi' ),
			'priority'   => __( 'Priority', 'wp-kusanagi' ),
			'devices'    => __( 'Devices', 'wp-kusanagi' ),
		);
		return $columns;
	}

	function display() {
		extract( $this->_args );
?>
<table class="wp-list-table <?php echo implode( ' ', $this->get_table_classes() ); ?>" cellspacing="0">
	<thead>
	<tr>
		<?php $this->print_column_headers(); ?>
	</tr>
	</thead>

	<tfoot>
	<tr>
		<?php $this->print_column_headers( false ); ?>
	</tr>
	</tfoot>

	<tbody id="the-list"<?php if ( $singular ) echo " class='list:$singular'"; ?>>
		<?php $this->display_rows_or_placeholder(); ?>
	</tbody>
</table>
<?php
	}

	function column_group_name( $group ) {
		$url = add_query_arg( array( 'action' => 'edit_group', 'group_id' => $group->group_id ) );
		echo '<p><a href="' . esc_url( $url ) . '">' . esc_html( $group->group_name ) . '</a><br />' . "\n";
	}

	function column_theme( $group ) {
		global $WP_KUSANAGI;
		if ( $group->theme ) {
			$theme = $WP_KUSANAGI->modules['theme-switcher']->avaiable_themes[$group->theme];
			if ( is_object( $theme ) ) {
				$theme = $theme->__get( 'name' );
			} else {
				$theme = $theme['Name'];
			}
		} else {
			$theme = '';
		}
		echo esc_html( $theme );
	}

	function column_slug( $group ) {
		echo esc_html( $group->slug );
	}

	function column_priority( $group ) {
		echo esc_html( $group->priority );
	}

	function column_devices( $group ) {
		global $WP_KUSANAGI;
		$devices = $WP_KUSANAGI->modules['theme-switcher']->get_group_relation_devices( $group->group_id );
		if ( $devices ) :
?>
<ul>
<?php
			foreach ( $devices as $device ) :
?>
	<li><?php echo esc_html( $device->device_name ); ?></li>
<?php
			endforeach;
?>
</ul>
<?php
		endif;
	}

	function column_default( $group, $column_name ) {
		do_action( 'theme_switcher_group_default_column', $column_name, $group );
	}
} // KUSANAGI_Device_Group_List_Table class end


class KUSANAGI_Device_List_Table extends WP_List_Table {
	function __construct( $args = array() ) {
		$args = wp_parse_args( $args, array(
			'plural'   => '',
			'singular' => '',
			'ajax'     => false,
			'screen'   => null,
		) );

		$screen = get_current_screen();
		$this->screen = $screen;

		if ( ! $args['plural'] ) {
			$args['plural'] = $screen->base;
		}
		$this->_args = $args;
		$this->_column_headers = array(
			$this->get_columns(),
			array(),
			array()
		);
	}

	function prepare_items() {
		global $WP_KUSANAGI;
		$this->items = $WP_KUSANAGI->modules['theme-switcher']->get_devices();
	}


	function get_columns() {
		$columns = array(
			'device'  => __( 'Device Name', 'wp-kusanagi' ),
			'keyword' => __( 'Keywords', 'wp-kusanagi' ),
			'group'   => __( 'Group', 'wp-kusanagi' ),
		);
		return $columns;
	}

	function display() {
		extract( $this->_args );
?>
<table class="wp-list-table <?php echo implode( ' ', $this->get_table_classes() ); ?>" cellspacing="0">
	<thead>
	<tr>
		<?php $this->print_column_headers(); ?>
	</tr>
	</thead>

	<tfoot>
	<tr>
		<?php $this->print_column_headers( false ); ?>
	</tr>
	</tfoot>

	<tbody id="the-list"<?php if ( $singular ) echo " class='list:$singular'"; ?>>
		<?php $this->display_rows_or_placeholder(); ?>
	</tbody>
</table>
<?php
	}

	function column_device( $device ) {
		$url = add_query_arg( array( 'action' => 'edit_device', 'device_id' => $device->device_id ) );
		echo '<a href="' . esc_url( $url ) . '">' . esc_html( $device->device_name ) . '</a>';
	}

	function column_keyword( $device ) {
		echo esc_html( $device->keyword );
	}

	function column_group( $device ) {
		global $WP_KUSANAGI;
		$groups = $WP_KUSANAGI->modules['theme-switcher']->get_device_relation_groups( $device->device_id );
		if ( $groups ) :
?>
<ul>
<?php
			foreach ( $groups as $group ) :
?>
	<li><?php echo esc_html( $group->group_name ); ?></li>
<?php
			endforeach;
?>
</ul>
<?php
		endif;
	}

	function column_default( $device, $column_name ) {
		do_action( 'theme_switcher_device_default_column', $column_name, $device );
	}
} // KUSANAGI_Device_List_Table class end

}

