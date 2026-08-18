import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbitune/core/widgets/custom_bottom_nav.dart';

void main() {
  testWidgets('CustomBottomNav renders items and handles tab switching', (WidgetTester tester) async {
    int selectedTab = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: StatefulBuilder(
            builder: (context, setState) {
              return CustomBottomNav(
                currentIndex: selectedTab,
                onTabSelected: (index) {
                  setState(() {
                    selectedTab = index;
                  });
                },
              );
            },
          ),
        ),
      ),
    );

    // Verify initial active tab label
    expect(find.text('Home'), findsOneWidget);

    // Tap on Search tab (second item)
    final searchIcon = find.byWidgetPredicate(
      (widget) => widget is GestureDetector,
    );
    expect(searchIcon, findsWidgets);

    // Tap the 2nd navigation item (Search)
    await tester.tap(searchIcon.at(1));
    await tester.pumpAndSettle();

    expect(selectedTab, 1);
    expect(find.text('Search'), findsOneWidget);

    // Tap the 3rd navigation item (Library)
    await tester.tap(searchIcon.at(2));
    await tester.pumpAndSettle();

    expect(selectedTab, 2);
    expect(find.text('Library'), findsOneWidget);
  });
}
