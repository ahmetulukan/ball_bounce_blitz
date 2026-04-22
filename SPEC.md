# Ball Bounce Blitz - Oyun Spesifikasyonu

## Genel Bakış
- **Tür**: Arcade/reflex oyunu (Flame engine, Flutter)
- **Platform**: iOS, Android, Web

## Hedef Kullanıcılar
- Mobil kullanıcılar için hızlı, eğlenceli oyun deneyimi

## Temel Mekanikler

### 1. Paddle Kontrolü
- Yatay hareket, mouse/touch ile drag
- Ekranın alt bölümünde sabit

### 2. Top (Ball)
- Sürekli yukarı doğru sekme
- Paddle'dan sekmesi = +10 puan
- Duvarlardan sekmesi = fizik
- Ekran dışına çıkması = can kaybı

### 3. Düşmanlar (Enemies)
- 4 farklı tür: Normal, Fast, Tough, Big
- Yukarı doğru hareket
- Top ile temas = hasar (türe göre 1-3 vuruş)

### 4. Wave Sistemi
- Her 15 düşman sonrası wave artışı
- Wave arttıkça düşman hızı ve spawn hızı artar
- Wave announcement ile görsel bildirim

### 5. Power-Up Sistemi
- Her ~8 saniyede rastgele düşer
- Speed Boost ⚡: 5 sn boyunca hız artışı
- Shield 🛡️: 8 sn, topu bir kez bloklar
- Multi-Ball ✖3: 2 extra top spawnla
- Paddle Shrink 🔻: Paddle'ı küçült
- Magnet 🧲: 6 sn, top'u paddle'a çeker

### 6. Combo Sistemi
- Ardışık hit'lerde combo artışı
- 5+ combo = bonus puan
- 2.5 sn içinde yeni hit yoksa sıfırlanır

### 7. Particle & Visual Effects
- Score particle: Sarı parçacıklar (+10 scorunda)
- Explosion effect: Kırmızı parçacıklar (can kaybında)
- Ball trail: Sarı/turuncu iz
- Screen shake: Darbe anında ekran sarsıntısı
- Starfield: Animasyonlu yıldızlar arka planı

## MVP Features
1. Paddle drag hareketi ✓
2. Top fiziği ve sekme ✓
3. 4 düşman türü ✓
4. Skor sistemi ✓
5. Wave sistemi ✓
6. 5 power-up türü ✓
7. Combo sistemi ✓
8. Particle effects ✓
9. Ball trail ✓
10. Screen shake ✓
11. Starfield ✓
12. Game over / restart ✓
13. High score persistence ✓

## Teknik
- Flutter + Flame ^1.18.0
- State management: flame built-in
- Collision detection: Flame hitbox
- SharedPreferences: High score persistence
- Audio manager: stubs hazır (flame_audio ile aktifleştirilebilir)
- Aspect: Landscape only, fullscreen
