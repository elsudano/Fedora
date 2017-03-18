<?php
	/**
	* busca en una base de datos de MAC el fabricante de dicha MAC
	*
	* Se puede pasar como parametro la MAC Address que queremos buscar
	* o tambien se puede poner en el script parte de la mac address y que
	* el script busque todas las posibilidades
	*/
	if (count($argv) > 1 && $argv[1] != ""){
		$url = "http://api.macvendors.com/" . urlencode($argv[1]);
		$ch = curl_init();
		curl_setopt($ch, CURLOPT_URL, $url);
		curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
		$response = curl_exec($ch);
		if($response) {
			echo "Vendor: $response \n";
		} else {
			echo "Not Found \n";
		}
	} else {
	for ($i = 0; $i <= 255; $i++) {
		$mc = str_pad(dechex($i),2,"0",STR_PAD_LEFT);
		$mac_address = "2C:60:$mc:00:00:00";
		$url = "http://api.macvendors.com/" . urlencode($mac_address);
		$ch = curl_init();
		curl_setopt($ch, CURLOPT_URL, $url);
		curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
		$response = curl_exec($ch);
		if (strcmp($response, "Vendor not found\n") != 0) {
			echo "Mac: $mac_address Vendor: $response \n";
			exit();
		}                
		sleep(rand(2,5));
	}
	}
?>
