# Grabaciones de llamadas

## Despliegue

El contenedor usa `/app/uploads/call-audio` y el VPS debe montar una ruta persistente:

```env
CALL_AUDIO_HOST_DIR=/srv/crm/call-audio
PUBLIC_BASE_URL=https://api-crm.hadacorp.com.mx
AUDIO_SIGNING_SECRET=un-secreto-largo-distinto-del-jwt
AUDIO_LINK_TTL_SECONDS=300
AUDIO_TRANSCODE=true
```

Crear `/srv/crm/call-audio`, asignarlo al UID/GID del contenedor y reconstruir el backend. No ejecutar `docker compose down -v`, porque `-v` también elimina volúmenes declarados.

## Migración y respaldo

Los archivos antiguos de `uploads/call-audio` deben copiarse directamente a `/srv/crm/call-audio`; las claves `/static/call-audio/<archivo>` se resuelven desde esa raíz. Conservar nombres y comprobar lectura desde el contenedor. Respaldar tanto MySQL como `/srv/crm/call-audio`; una copia sin la otra queda incompleta.

Definir una política de retención acorde al consentimiento y obligaciones de la empresa. No borrar archivos cuya llamada siga con `audio_estado = 'listo'` sin actualizar antes el registro correspondiente.

## Nginx

```nginx
client_max_body_size 120m;
proxy_request_buffering off;
proxy_buffering off;
proxy_read_timeout 600s;
proxy_send_timeout 600s;

location / {
    proxy_pass http://crm_backend:3000;
    proxy_set_header Range $http_range;
    proxy_set_header If-Range $http_if_range;
}
```

Express atiende solicitudes `Range` y puede responder `206`; Nginx debe reenviar esas cabeceras.

## Contrato de API

- `POST /api/v1/leads/calls/:id/audio`: autenticado; adjunta hasta 100 MB y responde `201` con `audio_estado: listo`.
- `GET /api/v1/calls/recordings`: solo admin; pagina y filtra las grabaciones del desarrollo activo.
- `GET /api/v1/calls/:id/audio-link`: autenticado; genera una URL absoluta y temporal para admin o agente dueño.
- `GET /api/v1/calls/:id/audio?exp=...&sig=...`: reproduce; `download=1` fuerza descarga. La URL firmada es temporal y no debe guardarse como enlace permanente.

La clave física nunca se expone en listados de llamadas. Los formatos no aptos para navegador se convierten a MP3 con ffmpeg cuando la conversión está habilitada.
