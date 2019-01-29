<?php if ( ! defined( 'ABSPATH' ) ) exit; ?>
<?php $s = $this->modules[$_GET['tab']]->settings; ?>
			<h3><?php _e( 'Translate Accelerator', 'wp-kusanagi' ); ?></h3>
			<table class="form-table">
			<tr>
				<th><?php _e( 'Enable to accleration.', 'wp-kusanagi' ); ?></th>
				<td>
					<label for="activate">
						<input type="checkbox" name="activate" id="activate" value="1"<?php echo $s['activate'] == 1 ? ' checked="checked"' : ''; ?> />
						<?php _e( 'Enable', 'wp-kusanagi' ); ?>
					</label>
				</td>
			</tr>
			<tr>
				<th><?php _e( 'Type', 'wp-kusanagi' ); ?></th>
				<td>
					<ul>
						<li><label for="cache_type_file"><input type="radio" name="cache_type" id="cache_type_file" value="file"<?php echo $s['cache_type'] == 'file' || ( $s['cache_type'] == 'apc' && ! function_exists( 'apc_store' ) ) ? ' checked="checked"' : ''; ?> /> <?php _e( 'Files', 'wp-kusanagi' ); ?></label><br />
							<?php _e( 'Cache directory :', 'wp-kusanagi' ); ?> <input type="text" size="50" name="file_cache_dir" value="<?php echo esc_html( $s['file_cache_dir'] ); ?>" />
						</li>
<?php if ( function_exists( 'apc_store' ) ) : ?>						<li><label for="cache_type_apc"><input type="radio" name="cache_type" id="cache_type_apc" value="apc"<?php echo ( $s['cache_type'] == 'apc' ) && function_exists( 'apc_store' ) ? ' checked="checked"' : ''; ?> /> <?php _e( 'APC', 'wp-kusanagi' ); ?></label></li><?php endif; ?>
					</ul>
				</td>
			</tr>
			<tr>
				<th><?php _e( 'Translated text displayed in your site', 'wp-kusanagi' ); ?></th>
				<td>
					<select name="frontend">
						<option value="cache"<?php echo $s['frontend'] == 'cache' ? ' selected="selected"' : ''; ?>><?php _e( 'Enable cache', 'wp-kusanagi' ); ?></option>
						<option value="cutoff"<?php echo $s['frontend'] == 'cutoff' ? ' selected="selected"' : ''; ?>><?php _e( 'Disable translation', 'wp-kusanagi' ); ?></option>
						<option value="defalut"<?php echo $s['frontend'] == 'defalut' ? ' selected="selected"' : ''; ?>><?php _e( "Use language file's for translation", 'wp-kusanagi' ); ?></option>
					</select>
				</td>
			</tr>
			<tr>
				<th><?php _e( 'Login/signup page translation', 'wp-kusanagi' ); ?></th>
				<td>
					<select name="wp-login">
						<option value="cache"<?php echo $s['wp-login'] == 'cache' ? ' selected="selected"' : ''; ?>><?php _e( 'Enable cache', 'wp-kusanagi' ); ?></option>
						<option value="cutoff"<?php echo $s['wp-login'] == 'cutoff' ? ' selected="selected"' : ''; ?>><?php _e( 'Disable translation', 'wp-kusanagi' ); ?></option>
						<option value="defalut"<?php echo $s['wp-login'] == 'defalut' ? ' selected="selected"' : ''; ?>><?php _e( "Use language file's for translation", 'wp-kusanagi' ); ?></option>
					</select>
				</td>
			</tr>
			<tr>
				<th><?php _e( 'Admin pages translation', 'wp-kusanagi' ); ?></th>
				<td>
					<select name="admin">
						<option value="cache"<?php echo $s['admin'] == 'cache' ? ' selected="selected"' : ''; ?>><?php _e( 'Enable cache', 'wp-kusanagi' ); ?></option>
						<option value="cutoff"<?php echo $s['admin'] == 'cutoff' ? ' selected="selected"' : ''; ?>><?php _e( 'Disable translation', 'wp-kusanagi' ); ?></option>
						<option value="defalut"<?php echo $s['admin'] == 'defalut' ? ' selected="selected"' : ''; ?>><?php _e( "Use language file's for translation", 'wp-kusanagi' ); ?></option>
					</select>
				</td>
			</tr>
			<tr>
				<th><?php _e( 'Delete cache', 'wp-kusanagi' ); ?></th>
				<td>
					<label for="cache_force_delete">
						<input type="checkbox" name="cache_force_delete" id="cache_force_delete" value="1" />
						<?php _e( 'Force deletion of all cache', 'wp-kusanagi' ); ?>
					</label>
				</td>
			</tr>
			</table>
