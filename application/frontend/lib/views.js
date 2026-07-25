const VIEW_OPTIONS = [
  {
    key: "dbpedia-artist-exported-view",
    name: "DBpedia Artist Exported View",
    uri: "svm:EV_DBpedia_Artist",
    type: "exported_view",
  },
  {
    key: "musicartist-fusion-view",
    name: "MusicArtist Fusion View",
    uri: "svm:EV_DBpedia_Artist",
    type: "fusion_view",
  },
  {
    key: "musicartist-linkset-view",
    name: "MusicArtist Linkset View",
    uri: "svm:EV_DBpedia_Artist",
    type: "linkset_view",
  },
  {
    key: "musicartist-unification-view",
    name: "MusicArtist Unification View",
    uri: "svm:EV_DBpedia_Artist",
    type: "unification_view",
  },
];

export async function loadViewOptions() {
  return VIEW_OPTIONS.map((view) => ({ ...view }));
}
