# sinatra-microgallery

Self-contained Photo Album built upon Sinatra Ruby framework

***

## Usage

### Requirements

* Sinatra 1.2.x
* haml
* RMagick
* json
* yaml
* exifr

### Upload Pictures

You can manually upload pictures to &lt;gallery_home&gt;/public/gallery/&lt;album_name&gt;, and the pictures will show up in the right album
Otherwise, you have the option of uploading the pictures from the administration panel

### Configuration

Modify configuration.yml

#### Administration Panel credentials

```bash
username: <username>
password: <password>
```

#### Gallery title (top left corner)

```bash
title: <title>
```

#### Gallery footer

```bash
footer: <footer>
```

#### Navigation (links on the top right corner)

```
navigation:
  Home: http://<host>
  Gallery: http://gallery.<host>
```

### Project Status

The software provided here is not maintained anymore, nor any update is planned for the future.
I decided to make it available on my repository as a reference
