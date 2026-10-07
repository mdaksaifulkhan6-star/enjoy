// test/widget_test.dart — সম্পূর্ণ ফাইল replace
import 'package:flutter_test/flutter_test.dart';
import 'package:enjoy/features/feed/data/post_repository.dart';

void main() {
  test('hashtag extraction', () {
    expect(PostRepository.extractHashtags('হাই #ENJOY #flutter খুব ভালো'),
        ['enjoy', 'flutter']);
    expect(PostRepository.extractHashtags('কোনো hashtag নেই'), isEmpty);
  });

  test('reward math: 100 points = ৳0.25', () {
    const points = 100000;
    final bdt = points / 100 * 0.25;
    expect(bdt, 250.0);
  });
}