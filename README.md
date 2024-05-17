Como adicionar o plugin em um gateway services via RestAPI do Kong: 

http://{kong-base-path}/services/{id}/plugins

Body:

{
	"name": "kong-rhsso",
	"config": {
		"rhsso_base_url": {RHSSO-BASE-PATH}, (Obrigatório)
		"clients": [
			{
				"client_id": {client_id}, (Obrigatório)
				"client_secret": {client_secret}, (Obrigatório)
				"realm": {realm}, (Obrigatório)
				"scope": {scopes} (Opcional)
			}
	    ...
		]
	}
}

Qualquer dúvida entrar em contato com pedrofarbo@gmail.com
