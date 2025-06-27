
## Para subir um Kong local

```bash
docker-compose up -d
```

## Como adicionar o plugin em um gateway services via RestAPI do Kong: 

```bash
curl -X POST http://localhost:8001/services/{id}/plugins \
 -d @- <<EOF
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
EOF

```

## Para listar plugins habilitados no gateway

```bash
curl localhost:8001/plugins/enabled | jq
```

Qualquer dúvida entrar em contato com pedrofarbo@gmail.com
