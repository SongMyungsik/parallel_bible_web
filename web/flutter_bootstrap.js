{{flutter_js}}
{{flutter_build_config}}

// Flutter 엔진이 준비되면 index.html의 "불러오는 중" 안내를 지우고 앱을 띄웁니다.
_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    document.getElementById('loading')?.remove();
    await appRunner.runApp();
  },
});
