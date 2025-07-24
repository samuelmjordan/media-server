open Lwt.Syntax
open Media_Metadata
open Tyxml.Html

let get_film_detail_screen file_id =
  let* metadat_result = Media_Metadata_Repository.find file_id in
  match metadat_result with
  | Error e -> Lwt.return (Error e)
  | Ok None ->
    let page = html
      (head
        (title (txt "not found"))
        [link ~rel:[`Stylesheet] ~href:"/static/style.css" ()])
      (body [])
    in Lwt.return (Ok page)
  | Ok Some metadata ->
    let backdrop_url = 
      "https://image.tmdb.org/t/p/w1280" ^ metadata.backdrop_path in
    let poster_url = 
      "https://image.tmdb.org/t/p/w500" ^ metadata.poster_path in
    let stream_url = "/api/stream/" ^ metadata.file_id in
    let page = html
      (head
        (title (txt metadata.title))
        [link ~rel:[`Stylesheet] ~href:"/static/style.css" ();
         script ~a:[] (Unsafe.data {|
        function showPlayer(streamUrl) {
          const container = document.getElementById('player-container');
          const video = document.getElementById('video-player');
          video.src = streamUrl;
          container.style.display = 'flex';
          video.play();
        }

        function hidePlayer() {
          const container = document.getElementById('player-container');
          const video = document.getElementById('video-player');
          video.pause();
          video.src = '';
          container.style.display = 'none';
        }
        |})])
      (body [
        div ~a:[a_class ["film-detail"]] [
          div ~a:[a_class ["backdrop"]] [
            img ~src:backdrop_url ~alt:metadata.title ();
          ];
          div ~a:[a_class ["detail-content"]] [
            div ~a:[a_class ["poster-section"]] [
              img ~src:poster_url ~alt:metadata.title ();
            ];
            div ~a:[a_class ["info-section"]] [
              h1 [txt metadata.title];
              p ~a:[a_class ["overview"]] [txt metadata.overview];
              div ~a:[a_class ["meta"]] [
                span [txt ("Release: " ^ metadata.release_date)];
                span [txt ("Rating: " ^ string_of_float metadata.popularity)];
              ];
              button ~a:[a_class ["play-btn"]; a_onclick ("showPlayer('" ^ stream_url ^ "')")] [txt "▶ Play"];
              a ~a:[a_href "/library"; a_class ["back-btn"]] [txt "← Back to Library"];
            ];
          ];
          (* hidden video player *)
          div ~a:[a_class ["video-player-container"]; a_id "player-container"] [
            video ~a:[a_class ["video-player"]; a_id "video-player"; a_controls ()] [];
            button ~a:[a_class ["close-player"]; a_onclick "hidePlayer()"] [txt "✕"];
          ];
        ];
      ])
    in Lwt.return (Ok page)