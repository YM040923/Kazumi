import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/plugins/anti_crawler_config.dart';
import 'package:kazumi/plugins/plugins.dart';
import 'package:kazumi/request/config/api_endpoints.dart';

void main() {
  Plugin pluginWith(AntiCrawlerConfig config) {
    return Plugin(
      api: ApiEndpoints.apiLevel.toString(),
      type: 'anime',
      name: 'compat',
      version: '1.0.0',
      muliSources: true,
      useWebview: true,
      useNativePlayer: true,
      usePost: false,
      useLegacyParser: false,
      adBlocker: false,
      userAgent: '',
      baseUrl: 'https://example.com',
      searchURL: 'https://example.com/search?q=@keyword',
      searchList: '//a',
      searchName: '.',
      searchResult: '.',
      chapterRoads: '//ul',
      chapterResult: './/a',
      referer: '',
      antiCrawlerConfig: config,
    );
  }

  test('api level matches upstream rule api 7', () {
    expect(ApiEndpoints.version, '2.1.6');
    expect(ApiEndpoints.apiLevel, 7);
  });

  test('anti crawler config parses api 7 custom script fields', () {
    final config = AntiCrawlerConfig.fromJson({
      'enabled': true,
      'captchaType': CaptchaType.customJavaScript,
      'captchaImage': '//img',
      'captchaInput': '//input',
      'captchaButton': '//button',
      'captchaDetectType': CaptchaDetectType.regex,
      'captchaDetectValue': 'verify\\s+required',
      'captchaScript': 'window.KazumiCaptcha.done();',
    });

    expect(config.captchaType, CaptchaType.customJavaScript);
    expect(config.captchaDetectType, CaptchaDetectType.regex);
    expect(config.captchaDetectValue, 'verify\\s+required');
    expect(config.captchaScript, 'window.KazumiCaptcha.done();');

    final json = config.toJson();
    expect(json['captchaDetectType'], CaptchaDetectType.regex);
    expect(json['captchaDetectValue'], 'verify\\s+required');
    expect(json['captchaScript'], 'window.KazumiCaptcha.done();');
  });

  test('plugin captcha challenge detection supports text and regex rules', () {
    final textPlugin = pluginWith(
      AntiCrawlerConfig(
        enabled: true,
        captchaType: CaptchaType.customJavaScript,
        captchaImage: '',
        captchaInput: '',
        captchaButton: '',
        captchaDetectType: CaptchaDetectType.text,
        captchaDetectValue: '请完成安全验证',
        captchaScript: 'window.KazumiCaptcha.done();',
      ),
    );

    expect(textPlugin.detectsCaptchaChallenge('<html>请完成安全验证</html>'), isTrue);
    expect(textPlugin.detectsCaptchaChallenge('<html>正常页面</html>'), isFalse);

    final regexPlugin = pluginWith(
      AntiCrawlerConfig(
        enabled: true,
        captchaType: CaptchaType.customJavaScript,
        captchaImage: '',
        captchaInput: '',
        captchaButton: '',
        captchaDetectType: CaptchaDetectType.regex,
        captchaDetectValue: r'captcha-\d+',
        captchaScript: 'window.KazumiCaptcha.done();',
      ),
    );

    expect(
        regexPlugin.detectsCaptchaChallenge('<div>captcha-42</div>'), isTrue);
    expect(
        regexPlugin.detectsCaptchaChallenge('<div>captcha-x</div>'), isFalse);
  });
}
