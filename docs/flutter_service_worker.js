'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {".git/COMMIT_EDITMSG": "a8297d555dd34879e8e48e1cf12acefa",
".git/config": "a148fa52519885645dfd522d8774e0ee",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/HEAD": "cf7dd3ce51958c5f13fece957cc417fb",
".git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
".git/hooks/commit-msg.sample": "579a3c1e12a1e74a98169175fb913012",
".git/hooks/fsmonitor-watchman.sample": "a0b2633a2c8e97501610bd3f73da66fc",
".git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
".git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
".git/hooks/pre-commit.sample": "5029bfab85b1c39281aa9697379ea444",
".git/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
".git/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
".git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
".git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
".git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
".git/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
".git/hooks/sendemail-validate.sample": "4d67df3a8d5c98cb8565c07e42be0b04",
".git/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
".git/index": "93f09b8d995f5a0272f801d4f7b46464",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "1600713fc88c01fd57b484aad86cbea3",
".git/logs/refs/heads/main": "4b0e185e96a3b17ef79c76c5056be1fa",
".git/logs/refs/remotes/origin/main": "73604f9b23966fcf144e32aef3a5c6ed",
".git/objects/08/0515f458ba5ae872532860d43606de951d52fd": "580762a0468a1d921d0fd5d4e76aa6a3",
".git/objects/0b/b8b5cc1091817c052bd36c12ef23878a9dafc2": "2b9bf1bcfaae9ade15e0149419a2fb1c",
".git/objects/0b/da228ade88b0bb5aac7da2c881d0c3f64d0817": "02c3f38c13f78243f1c52e7cbb8200cb",
".git/objects/0d/d30d4069d29dbf22903cdcd7f55f05c1545523": "9a47deb738235536e960568e086c3c1c",
".git/objects/0f/d5ac79efb2457f3462d1a3026749156e2ce92d": "0d1efb4b041f8c6ce5d57389d8ba5df5",
".git/objects/16/7667d203d98f5b27c3ff58d486eea9c5287fe4": "0c316621a6f73b3674c16c36159374df",
".git/objects/19/82f38ab21303459aa1155265052ca599fa58d1": "a293dd17a2e66acae6527c2621b5e28f",
".git/objects/1a/6ac9dfdc8c40f6338ad0dfaff34c1b5f184b7b": "396319651fa37f03560dfe8bec5b6e5d",
".git/objects/1c/34522e1b63f4cdb8e69020be6fa1d642ef8adf": "9e34ebb4cf43041f30f8c3e8e77b1751",
".git/objects/1d/468b85698a60041b450286f31b3264b3bbd6f7": "5c8c497111befde32ac151f14cf92f85",
".git/objects/20/7d60cc2427a174918659dae998304eaae5a374": "df15f7e1893a3a61a041c3b955fe51f0",
".git/objects/24/4a6499a3cfd871a4a92c9637e07e67cd0d19e4": "e19bcb559de3093f9aee77eafa197a73",
".git/objects/24/c069cbde639ff8d87451c53f7189d70d2c06a1": "04e18688a30046d57021b31aee07e3fe",
".git/objects/28/083a22b9bcbf32d95b78680cedf86e8267b715": "f81d60d6b2571eeeb279f6007df771ec",
".git/objects/2b/c5131b05bef6c48a27d25061f6b25f0af48821": "67c766cb19787fa8af5ec549470d932c",
".git/objects/35/96d08a5b8c249a9ff1eb36682aee2a23e61bac": "e931dda039902c600d4ba7d954ff090f",
".git/objects/36/62dcfe0223f690d3ceeea287b20a740f7b509d": "b94718cccf215c477da99cf1bff38e96",
".git/objects/39/ceebdb796df90d53e93f0784ccddd8daa26255": "3c56bb91448b7c4c52141546897d35aa",
".git/objects/3d/8c749ba6e226b41ae8acaa5aaf1237abbc1860": "35257df2fe9f0ed2ffe04685e29b93ff",
".git/objects/40/1184f2840fcfb39ffde5f2f82fe5957c37d6fa": "1ea653b99fd29cd15fcc068857a1dbb2",
".git/objects/41/0f8a3a84ac95ff7c7fd6951b23c254e706675c": "4118fd9f65166186324f415cb6f953be",
".git/objects/45/7b1e9e26d178b922e6fe304a459830f761bd63": "3a423a19a248ac1d44e5baa3a16acae3",
".git/objects/51/9385f3905c854993c85e2b91443213847552ed": "21915f25d86d72e65c287ba55319708e",
".git/objects/51/f2ed32c0fcfbd6e73e9266f2ed6a4f2a8eba25": "da7aad36df6506f3de5ca2a60890e7a0",
".git/objects/53/3402c75429e6feaa7b8f92878ae2313dbdf2de": "63ab067b0b447b461fa3e8f58a1f23a9",
".git/objects/57/7946daf6467a3f0a883583abfb8f1e57c86b54": "846aff8094feabe0db132052fd10f62a",
".git/objects/5c/b14abcbcc0b55f83e6c467adf0e8c479c059bb": "2f6fac99da123edeabf8e405ac1ff06b",
".git/objects/5f/bf1f5ee49ba64ffa8e24e19c0231e22add1631": "f19d414bb2afb15ab9eb762fd11311d6",
".git/objects/66/12e5228fcdeabd840f4ca17de889ca447e22f4": "183608f312c18e331794ec7a243cdb7b",
".git/objects/69/a7a5edac7837f200e10e47b3981a3a4ff7b357": "5ed2a00ec409e62947d6c7fe37a22623",
".git/objects/6b/9862a1351012dc0f337c9ee5067ed3dbfbb439": "85896cd5fba127825eb58df13dfac82b",
".git/objects/6c/9a212ec73a9627510973d679241e026aa7d714": "2eddc1ecf4f1755605ac8ef5595c4c62",
".git/objects/6d/6e77c5178496055f50e43580b0e660140743c3": "ada67acdbc2ad2fa068679148770fa42",
".git/objects/6f/c76b0fe1c720ba739ae17068140030b74cd22b": "2c7a99a3e0d904765cad740a7a2f9691",
".git/objects/71/3d9e0bab2b8d1558d7892c537fdfd0129e6aa6": "f1e90c9597f6964b903d2e2c5adc3a18",
".git/objects/72/3d030bc89a4250e63d16b082affe1998618c3f": "e4299c419434fc51f64a5266659918fa",
".git/objects/72/3f761622de2ba7282d3729a21a607e9d10b101": "ce16a85a26f59d511a2e246501ebe74b",
".git/objects/85/c7f0eb016fb87242ac785fb81cdb9eb6cdb581": "3f70e2181f4bf852888b9e43f8a7cf57",
".git/objects/88/773b2206edd7ce4a4c359ea75f6cbbbfc0dd5a": "8706073966f1e45028123ba615dfb07b",
".git/objects/88/cfd48dff1169879ba46840804b412fe02fefd6": "e42aaae6a4cbfbc9f6326f1fa9e3380c",
".git/objects/8a/51a9b155d31c44b148d7e287fc2872e0cafd42": "9f785032380d7569e69b3d17172f64e8",
".git/objects/8a/aa46ac1ae21512746f852a42ba87e4165dfdd1": "1d8820d345e38b30de033aa4b5a23e7b",
".git/objects/8c/f6b3044b5a0a347599bab87141eab345e92190": "01bd81bb9744acc9f1e3ee1dc1a1b363",
".git/objects/8f/c8be62f202c40e7d3e2e16242fb065cfc4e1a7": "6fda1b80da67a8d96186cf8ab8b24087",
".git/objects/90/02e10fc15d7dde6c575fb6fe449c3bcfac4303": "b7eddc62ae956cb63eac7083ca0c400e",
".git/objects/91/4a40ccb508c126fa995820d01ea15c69bb95f7": "8963a99a625c47f6cd41ba314ebd2488",
".git/objects/92/f799718d8c9882252b57d3778010b253dcf38e": "c5dcc67b96360e9babaa000ce80536f0",
".git/objects/93/1ae8fdc6a32eaa6666f31343f5cd37e74954a4": "db5174e1ae6c9ee16cbaa79d9ae9af48",
".git/objects/95/355e52878be653c7f5f4ccd87722f9315f8dfa": "05d97f76b73fb44ee9ce2799059193dd",
".git/objects/9b/fe19e11afb0a5c8318638f823ca5a00589dbf9": "7853605e89e5fc29406e8d2efdf65944",
".git/objects/a4/c0a0239e9ca1c6c51bd6303e50fae7f1bdfcd3": "f51530c48cef9607cfb2e88d619476e0",
".git/objects/a5/3387e3438530f865e6e3aab83c73d42189d896": "bc56fffc3b497ef11bd9b83895411f13",
".git/objects/a5/90f5c3e4902a7cb10f4bbc5da0e65e667f7950": "fb4b949d2276d198ee88eef0e3fde2b1",
".git/objects/a5/de584f4d25ef8aace1c5a0c190c3b31639895b": "9fbbb0db1824af504c56e5d959e1cdff",
".git/objects/a6/7d457ddc0a3257f68677f5c9efdefa0a3a77e2": "9f3e0e7f6b8068704a98fb35abeca7dd",
".git/objects/a7/96fbcc706179f3eb66f03ffc511e92b483e3e3": "f691fbf756ec21a582ac8288ac1c6a89",
".git/objects/a8/8c9340e408fca6e68e2d6cd8363dccc2bd8642": "11e9d76ebfeb0c92c8dff256819c0796",
".git/objects/b4/97ab3e5d3f0d78b76b285b87b80df0bfad8c96": "7de7042d3b1d6ca3b3368587929a1842",
".git/objects/b7/49bfef07473333cf1dd31e9eed89862a5d52aa": "36b4020dca303986cad10924774fb5dc",
".git/objects/b9/2a0d854da9a8f73216c4a0ef07a0f0a44e4373": "f62d1eb7f51165e2a6d2ef1921f976f3",
".git/objects/ba/144ee5f6bcddf3688b471fa976847c0cccbbd2": "b655993b4144bf7ab434874b024b4a6d",
".git/objects/c0/a0c2ce1b2346b497827e4efe9e3dc77acf09d6": "d60f2bca7cf9a579f3abbefef0963cc0",
".git/objects/c3/0ad104723a0e6e00e54768626cb02c5fdf6aee": "ebeda149e3a8df1ed446e8d8dc30fbfe",
".git/objects/c6/9ec2f9ebbcb0bafe22c674d1a06e00fd8d120b": "d200ea19b47ca0cec35b4f820f9ddd0a",
".git/objects/cd/af1ea68eb7a0d3f785fe8e4e8edf5e1dfc88f0": "e8b0731dae1b2cb358d6bef328b8bfc6",
".git/objects/d0/b11e3959c926e3711c2d4ae18fe523f19caff2": "433f3f9f7d445095ba1f1a6db2734f4e",
".git/objects/d1/62312094828608f022a3a7974c30b9fa004f45": "0ef31b685bd9cf74d221f34e361d57a5",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/objects/d5/64d0bc3dd917926892c55e3706cc116d5b165e": "ab5f20dcd5b558888db7d80b0f979f8a",
".git/objects/d6/9c56691fbdb0b7efa65097c7cc1edac12a6d3e": "868ce37a3a78b0606713733248a2f579",
".git/objects/d7/7cfefdbe249b8bf90ce8244ed8fc1732fe8f73": "9c0876641083076714600718b0dab097",
".git/objects/d9/3952e90f26e65356f31c60fc394efb26313167": "1401847c6f090e48e83740a00be1c303",
".git/objects/e6/9de29bb2d1d6434b8b29ae775ad8c2e48c5391": "c70c34cbeefd40e7c0149b7a0c2c64c2",
".git/objects/e8/c181b7dbdf565b13eafceda711604291e42109": "351db66ace9e9d123a48c686e5627567",
".git/objects/e9/94225c71c957162e2dcc06abe8295e482f93a2": "2eed33506ed70a5848a0b06f5b754f2c",
".git/objects/eb/9b4d76e525556d5d89141648c724331630325d": "37c0954235cbe27c4d93e74fe9a578ef",
".git/objects/eb/a5d6c411eef5be4a72f122defbf76ed1fdb6ee": "30305d08d1f3875ebef7c7924daeea94",
".git/objects/ee/8b72f51015219cecd5478a024d9511be2fc18d": "25d1fb7a0403804df9cd7dac17f434c5",
".git/objects/ef/b875788e4094f6091d9caa43e35c77640aaf21": "27e32738aea45acd66b98d36fc9fc9e0",
".git/objects/f0/269f07478598fbf5954ea60fe3210c9f260824": "03e6b2b1c9d17b20792c8134219e7cd0",
".git/objects/f2/04823a42f2d890f945f70d88b8e2d921c6ae26": "6b47f314ffc35cf6a1ced3208ecc857d",
".git/objects/f3/709a83aedf1f03d6e04459831b12355a9b9ef1": "538d2edfa707ca92ed0b867d6c3903d1",
".git/objects/f5/72b90ef57ee79b82dd846c6871359a7cb10404": "e68f5265f0bb82d792ff536dcb99d803",
".git/objects/f7/d04832c1f1fda027d4469e3c609db37c23755f": "81fc05e1c19310599865562674ff86d7",
".git/objects/fa/6ef727bbcca1d2b579132a276a61a7054ce44b": "e58fb018f29c739311b743f99ac5aa61",
".git/objects/fd/31edaad850392725ac3ec5c5a87e78236aa57e": "775a1c30bce9285371f3b328b7e92ae6",
".git/refs/heads/main": "21f3984aba126b3ec30fc9aa9b7a2618",
".git/refs/remotes/origin/main": "21f3984aba126b3ec30fc9aa9b7a2618",
"assets/AssetManifest.bin": "b8f4b898f389afa981579cc56f7546ea",
"assets/AssetManifest.bin.json": "ed0130a8d82b53f4e615441aa1ce0149",
"assets/AssetManifest.json": "f3faa1fb977b8a47cc115cda44f3f983",
"assets/assets/animations/Animation_check.json": "4f052988ef78c567589a328eb185ef91",
"assets/assets/animations/Animation_intro.json": "6cf041cd49d3aa339587b3ba0e75fc20",
"assets/assets/animations/Animation_load.json": "5f16dd2b81e0fa7c2a96000dfaedeeda",
"assets/assets/animations/Animation_wave.json": "37661c9b4f7b8f79a71196d82b315301",
"assets/assets/animations/loading.json": "217d5d8845e39a69a907daad4fef2000",
"assets/assets/animations/welcome_animation.json": "3f27a2888a528307dbbfb1f311f6a708",
"assets/assets/fonts/Poppins-Black.ttf": "005bf0ac0e3d80eac4c5514de280ae83",
"assets/assets/fonts/Poppins-Bold.ttf": "92934d92f57e49fc6f61075c2aeb7689",
"assets/assets/fonts/Poppins-ExtraBold.ttf": "12fa32ab93fb44850f24fc1da0d6004d",
"assets/assets/fonts/Poppins-ExtraLight.ttf": "66292bc2ab55b992b6efd4a63b950d67",
"assets/assets/fonts/Poppins-Light.ttf": "7c448dffabdec11c8a24e013e87d9a7e",
"assets/assets/fonts/Poppins-Medium.ttf": "20aaac2ef92cddeb0f12e67a443b0b9f",
"assets/assets/fonts/Poppins-Regular.ttf": "09acac7457bdcf80af5cc3d1116208c5",
"assets/assets/fonts/Poppins-SemiBold.ttf": "2c63e05091c7d89f6149c274971c7c23",
"assets/assets/fonts/Poppins-Thin.ttf": "9b3fd4fadb0a6be3e3cd9075fd2a1e5b",
"assets/assets/images/clubs/delta.png": "0e3a4e9ac675aedc9ef565d362fb3dd0",
"assets/assets/images/clubs/educators.png": "c9bc0eb75c9595c708f5cbad36f0d85b",
"assets/assets/images/clubs/elem.png": "5911bfba810b6397129e283906833db8",
"assets/assets/images/clubs/eng.png": "9e8ee953a3327989592842d3e264b35c",
"assets/assets/images/clubs/kaupod.png": "f102379b334cd39b291b7097f7b3bd3d",
"assets/assets/images/clubs/math.png": "2d18d524160e3cdb033c1f8dde6f47d0",
"assets/assets/images/clubs/ministry.png": "78943b065a1bfd46e8f448c3ec1fed84",
"assets/assets/images/clubs/pschy.png": "916e0cea3faccbbb274823a6cf75f4b9",
"assets/assets/images/clubs/redcross.png": "d2b962cbf003c7a378fe994558353cd4",
"assets/assets/images/clubs/system.png": "059534047f6d053e760297efb53f379e",
"assets/assets/images/clubs/united.png": "71d3daeeaf891d14d7a9d5da58d3e728",
"assets/assets/images/ssulg.png": "cb7540cc314c2684e4b77af51a4beab4",
"assets/FontManifest.json": "f477ffc5a4f1828ffbe010aa4eb65b6b",
"assets/fonts/MaterialIcons-Regular.otf": "912caf961fa991c3af6c826cfa4ba43b",
"assets/NOTICES": "41916741705dfdfc87b7ae26acae74b6",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "6cfe36b4647fbfa15683e09e7dd366bc",
"canvaskit/canvaskit.js.symbols": "68eb703b9a609baef8ee0e413b442f33",
"canvaskit/canvaskit.wasm": "efeeba7dcc952dae57870d4df3111fad",
"canvaskit/chromium/canvaskit.js": "ba4a8ae1a65ff3ad81c6818fd47e348b",
"canvaskit/chromium/canvaskit.js.symbols": "5a23598a2a8efd18ec3b60de5d28af8f",
"canvaskit/chromium/canvaskit.wasm": "64a386c87532ae52ae041d18a32a3635",
"canvaskit/skwasm.js": "f2ad9363618c5f62e813740099a80e63",
"canvaskit/skwasm.js.symbols": "80806576fa1056b43dd6d0b445b4b6f7",
"canvaskit/skwasm.wasm": "f0dfd99007f989368db17c9abeed5a49",
"canvaskit/skwasm_st.js": "d1326ceef381ad382ab492ba5d96f04d",
"canvaskit/skwasm_st.js.symbols": "c7e7aac7cd8b612defd62b43e3050bdd",
"canvaskit/skwasm_st.wasm": "56c3973560dfcbf28ce47cebe40f3206",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"firebase-config.js": "f098fbfb5ca3658e619a19a2f3dded66",
"flutter.js": "76f08d47ff9f5715220992f993002504",
"flutter_bootstrap.js": "e60407b731c431a62778ca8fe9fce1ab",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "12c2a5bf39a579c16da89bb8e804ed07",
"/": "12c2a5bf39a579c16da89bb8e804ed07",
"main.dart.js": "2f364b84a3564a150cd50fee739f3603",
"manifest.json": "56a52f33215ace90fb23cb9381f866a6",
"README.md": "d65ff655abdddac612955f2737a9e49a",
"version.json": "764b27601824a6eb5ba42ec0a8e616f9"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
