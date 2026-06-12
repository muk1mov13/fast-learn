# Texnik ijodkorlik va konstruksiyalash — mobil o'quv ilovasi

Magistrlik dissertatsiyasining amaliy mahsuli. "Texnik ijodkorlik va konstruksiyalash" fanini mobil ilova orqali, **4 bosqichli didaktik model** (motivatsiya → o'zlashtirish → mustahkamlash → baholash) asosida o'qitish uchun mo'ljallangan.

## Imkoniyatlar
- 8 ta mavzu, har biri 6 bo'limli o'quv oqimi: **Video · Dars · Glossariy · Krossvord · Savollar · Amaliyot · Test**
- Avtomatik baholanadigan test (A/B/C/D), natija foizi va tahlil
- Progress saqlash, mavzularni bosqichma-bosqich ochish (gating)
- Gamifikatsiya: ball, nishonlar (badge), streak
- Premium UI: animatsiyalar, 3D flip flashcard, progress halqalari, **tungi rejim**
- To'liq **offline** ishlaydi (kontent assetlarda, progress qurilmada)

## Texnologiya
Flutter · Riverpod · go_router · google_fonts · flutter_animate · shared_preferences.
> Codegen (build_runner/freezed) talab qilinmaydi — `flutter pub get` dan so'ng darrov ishga tushadi.

## Ishga tushirish

Bu paket faqat manba kod (`lib/`, `assets/`, `pubspec.yaml`) dan iborat — `android/`, `ios/` kabi platforma papkalari yo'q. Ularni bir marta yaratish kerak:

```bash
# 1) Loyiha papkasida platforma fayllarini yarating (mavjud lib/ ni o'chirmaydi)
flutter create .

# 2) Bog'liqliklarni o'rnating
flutter pub get

# 3) Ishga tushiring
flutter run
```

Test va tahlil:
```bash
flutter test
flutter analyze
```


## Kontentni tahrirlash
Barcha o'quv materiali `assets/content/topic_1.json … topic_8.json` fayllarida. **Kodga tegmasdan** shu JSON fayllarni tahrirlab, ma'ruza matni, glossariy, krossvord, savollar va test savollarini yangilashingiz mumkin.

Fayl tuzilmasi:
```jsonc
{
  "id": 1, "order": 1, "title": "...", "isUnlocked": true,
  "video":   { "title": "...", "duration": "04:20" },
  "lesson":  { "title": "...", "bodyMarkdown": "...", "slideTitles": ["..."] },
  "glossary":[ { "term": "...", "definition": "..." } ],
  "crossword":[ { "orientation": "Gorizontal|Vertikal", "clue": "...", "answer": "..." } ],
  "questions":[ "..." ],
  "practical":{ "task": "...", "requirement": "..." },
  "test":    [ { "question": "...", "options": ["A","B","C","D"], "correctIndex": 1 } ]
}
```
`correctIndex`: 0=A, 1=B, 2=C, 3=D.

> **Eslatma:** 8-mavzu testi hozircha bo'sh (`"test": []`) — manbadagi material variantli emas edi. Ilova bo'sh testni xatosiz ko'rsatadi ("Test tez orada"). Savol qo'shsangiz, baholash avtomatik ishlaydi.

## Loyiha tuzilmasi
```
lib/
  main.dart
  app/theme/        # dizayn tizimi (ranglar, tipografiya, mavzular)
  app/router/       # go_router
  data/models/      # Topic, Lesson, TestQuestion, TopicProgress ...
  data/repositories/# Content + Progress repozitoriylari (interfeys + lokal)
  state/            # Riverpod providerlar, ProgressNotifier (ball/nishon/gating)
  features/         # splash, home, topic(+stages), progress, profile, shell
  widgets/          # ProgressRing, GradientButton, AppCard, StageTag ...
assets/content/     # topic_1.json ... topic_8.json
```

## Kelajakdagi kengaytmalar
- **Firebase** (Auth/Firestore/Storage): `ContentRepository` va `ProgressRepository` interfeyslari shu uchun abstrakt qilingan — yangi implementatsiya qo'shsangiz kifoya.
- **O'qituvchi paneli**, **3D/konstruktor moduli** (model_viewer_plus), real **video** (video_player/chewie), **Lottie** konfetti.
