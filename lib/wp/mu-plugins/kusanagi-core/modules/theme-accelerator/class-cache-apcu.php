<?php

/**
 * APC class
 */
class KUSANAGI_Cache_Apcu {
	/**
	 * Adds data
	 *
	 * @param string  $key
	 * @param mixed   &$var
	 * @param integer $expire
	 * @param string  $group  Used to differentiate between groups of cache values
	 * @return boolean
	 */
	public function add( $key, &$var, $expire = 0, $group = '' ) {
		if ( false === $this->get( $key, $group ) ) {
			return $this->set( $key, $var, $expire, $group );
		}

		return false;
	}

	/**
	 * Sets data
	 *
	 * @param string  $key
	 * @param mixed   $var
	 * @param integer $expire
	 * @param string  $group  Used to differentiate between groups of cache values
	 * @return boolean
	 */
	public function set( $key, $var, $expire = 86400 * 30, $group = '' ) {
		$storage_key = $this->get_item_key( $key );

		return apcu_store( $storage_key, serialize( $var ), $expire );
	}

	/**
	 * Returns data
	 *
	 * @param string  $key
	 * @param string  $group Used to differentiate between groups of cache values
	 * @return mixed
	 */
	public function get( $key, $group = '' ) {
		$storage_key = $this->get_item_key( $key );
		$v           = @unserialize( apcu_fetch( $storage_key ) );

		return $v;
	}

	/**
	 * Replaces data
	 *
	 * @param string  $key
	 * @param mixed   $var
	 * @param integer $expire
	 * @param string  $group  Used to differentiate between groups of cache values
	 * @return boolean
	 */
	public function replace( $key, &$var, $expire = 0, $group = '' ) {
		if ( false !== $this->get( $key, $group ) ) {
			return $this->set( $key, $var, $expire, $group );
		}

		return false;
	}

	/**
	 * Deletes data
	 *
	 * @param string  $key
	 * @param string  $group
	 * @return boolean
	 */
	public function delete( $key, $group = '' ) {
		$storage_key = $this->get_item_key( $key );

		return apcu_delete( $storage_key );
	}

	/**
	 * Flushes all data
	 *
	 * @param string  $group Used to differentiate between groups of cache values
	 * @return boolean
	 */
	public function flush( $group = '' ) {
		$data = apcu_clear_cache();

		return $data;
	}

	/**
	 * Checks if engine can function properly in this environment
	 *
	 * @return bool
	 */
	public function available() {
		return function_exists( 'apcu_store' );
	}

	/**
	 * Use key as a counter and add integet value to it
	 */
	public function counter_add( $key, $value ) {
		if ( 0 === $value ) {
			return true;
		}

		$storage_key = $this->get_item_key( $key );
		$r           = apcu_inc( $storage_key, $value );
		if ( ! $r ) {
			$this->counter_set( $key, 0 );
		}

		return $r;
	}

	/**
	 * Use key as a counter and add integet value to it
	 */
	public function counter_set( $key, $value ) {
		$storage_key = $this->get_item_key( $key );

		return apcu_store( $storage_key, $value );
	}

	/**
	 * Get counter's value
	 */
	public function counter_get( $key ) {
		$storage_key = $this->get_item_key( $key );
		$v           = (int) apcu_fetch( $storage_key );

		return $v;
	}

	public function get_item_key( $name ) {
		$key = sprintf( 'kusanagi_theme_accelerator_%s', $name );

		return $key;
	}
}
