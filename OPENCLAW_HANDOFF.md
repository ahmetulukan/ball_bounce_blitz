# OpenClaw Devir-Teslim / Yol Haritası

Bu dosya, proje üzerinde yapılan değişikliklerin ve sıradaki adımların tek bir yerden takip edilmesi için oluşturuldu. OpenClaw agent bundan sonra yaptığı değişiklikleri de **aynı dosyaya** ekleyerek ilerlemeli.

## Proje durumu (özet)
- **Teknoloji**: Flutter + Flame
- **Giriş**: `lib/main.dart` → `GameScreen` → `GameWidget` → `BallBounceBlitzGame` / `GameScene`
- **Durum**: Web build alınabiliyor; iOS build tarafındaki plugin/pods sorunları giderildi.

## Bu oturumda yapılan değişiklikler (nereden → nereye)

### 1) Flutter “app” yapısı eksikleri tamamlandı
- **Önce**: Repoda `android/`, `ios/`, `web/` vb. platform klasörleri yoktu; `flutter run/build` pratikte mümkün değildi.
- **Sonra**: `flutter create .` ile standart Flutter proje iskeleti üretildi:
  - `android/`, `ios/`, `web/`, `macos/`, `windows/`, `linux/`
  - `.metadata`, `analysis_options.yaml`, `test/` vb.

### 2) Flame sürüm uyumsuzluğu düzeltildi (pub get blokajı)
- **Önce**: `pubspec.yaml` içinde `flame: ^1.37.0` vardı; mevcut SDK ile dependency çözümü hata veriyordu.
- **Sonra**: `flame: ^1.35.1` ile uyumlu hale getirildi ve `flutter pub get` çalışır hale geldi.
- **Dosya**: `pubspec.yaml`

### 3) Test dosyası “MyApp yok” hatası düzeltildi
- **Önce**: `test/widget_test.dart` default Flutter counter test’ini kullanıyordu ve `MyApp` sınıfı projede olmadığı için analiz/build süreçlerinde hata doğuruyordu.
- **Sonra**: Uygulamanın açılıp Home UI text’inin geldiğini kontrol eden basit smoke test’e dönüştürüldü.
- **Dosya**: `test/widget_test.dart`

### 4) iOS: `shared_preferences_foundation` “Module not found” düzeltildi
- **Önce**: Xcode build sırasında `GeneratedPluginRegistrant` içinde `shared_preferences_foundation` bulunamıyordu.
- **Kök neden**:
  - CocoaPods kurulumunun/entegrasyonunun eksik kalması
  - Flutter `.xcconfig` dosyalarında Pods include’larının etkin olmaması
- **Sonra**:
  - `ios/Flutter/Debug.xcconfig` ve `ios/Flutter/Release.xcconfig` içinde Pods include’ları aktif edildi
  - Eksik `ios/Flutter/Profile.xcconfig` eklendi
  - `ios/Podfile` içine `platform :ios, '13.0'` eklendi
  - `pod install` tekrarlandı
  - `flutter build ios --no-codesign` ile doğrulandı
- **Dosyalar**:
  - `ios/Flutter/Debug.xcconfig`
  - `ios/Flutter/Release.xcconfig`
  - `ios/Flutter/Profile.xcconfig` (yeni)
  - `ios/Podfile`

### 5) Flame crash: “component is detached / game == null” düzeltildi
- **Önce**: `ScoreDisplay` constructor içinde `game.size` okuyordu. Component tree’ye eklenmeden `game` erişimi Flame assertion ile crash üretiyordu (Play sonrası siyah ekran).
- **Sonra**: `game.size` erişimi `onLoad`/`onGameResize` aşamasına taşındı.
- **Ek**: `PowerUpDisplay`’da her frame `game.size` okuma yerine `onLoad/onGameResize` ile konumlandırma yapıldı.
- **Dosyalar**:
  - `lib/components/score_display.dart`
  - `lib/components/power_up_display.dart`

### 6) Oyun fizik bug: Top üst duvarda “takılı kalıyor” düzeltildi
- **Önce**: Top üst sınıra çarpınca `velocity.y` yanlış yönde ayarlanıyordu, top yukarı gidip “orada kalmış gibi” davranıyordu.
- **Sonra**: Üst çarpışmada topun aşağı doğru sekmesi sağlandı.
- **Dosya**: `lib/components/ball.dart`

### 7) Power-up’lar paddle ile toplanmıyordu → paddle collision ile toplanır hale getirildi
- **Önce**: Power-up’lar sadece **top ile collision** olunca toplanıyordu; paddle’a geldiğinde reaksiyon yoktu.
- **Sonra**: Power-up `CollisionCallbacks` ile **Paddle** ile çarpışınca `collectPowerUp` çağırıyor ve yok oluyor.
- **Dosyalar**:
  - `lib/components/power_up.dart`
  - `lib/game/scene/game_scene.dart` (spawn parametresi)

### 8) Orientation davranışı (test stabilitesi için)
- **Önce**: Dikey çevirme denemelerinde iOS tarafında görsel “flicker/black” gibi sorunlar raporlandı.
- **Sonra**: Test aşamasında kararlılık için uygulama **landscape**’e kilitlendi.
- **Dosya**: `lib/main.dart`

## Build doğrulamaları
- **Web**: `flutter build web --release` başarılı (`build/web`)
- **iOS**: `flutter build ios --no-codesign` başarılı (`build/ios/iphoneos/Runner.app`)

## Asset/medya durumu
- `pubspec.yaml` sadece `assets/audio/` tanımlıyor.
- Test sürecinde “sessiz mod” hedeflendiği için **ses dosyaları eklenmedi** (audio manager zaten stub).
- Not: Audio dosyaları eklenecekse beklenen isimler: `hit.wav`, `score.wav`, `powerup.wav`, `gameover.wav`, `explosion.wav`.

### 2026-04-23 - Critical Hit Zone sisteminin eklenmesi
- Neden: OPENCLAW_HANDOFF.md'de "Risk–ödül vuruş bölgeleri (paddle kenarları kritik)" önerisi vardı
- Ne değişti: Paddle'ın kenarlarında kritik vuruş bölgesi eklendi (paddle edges = bonus puan)
- Dosyalar: lib/components/paddle.dart, lib/components/ball.dart
- Doğrulama: paddle.dart'ta _isCriticalHitZone() metodu ve render()'da görsel gösterge

### YYYY-MM-DD - <kısa başlık>
- Neden: …
- Ne değişti: …
- Dosyalar: …
- Doğrulama: (flutter analyze / build / run notları)

## OpenClaw için sıradaki adımlar (önerilen)
- **Oynanış farklılaştırma**:
  - Paddle “spin/curve” (drag hızına göre falso)
  - Risk–ödül vuruş bölgeleri (paddle kenarları kritik)
  - Düşman davranış çeşitleri (dodge/parçalanma/şok dalgası)
- **Portrait desteği istenecekse**: UI düzeni + fizik sınırları portrait’e göre yeniden ele alınmalı (şu an landscape kilitli).

## Değişiklik kaydı formatı (OpenClaw eklesin)
Lütfen yeni değişiklikleri aşağıdaki şablonla bu dosyanın en üstüne (bu bölümün altına) ekleyin:

```
### YYYY-MM-DD - <kısa başlık>
- Neden: …
- Ne değişti: …
- Dosyalar: …
- Doğrulama: (flutter analyze / build / run notları)
```

