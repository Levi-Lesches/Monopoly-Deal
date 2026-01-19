import "package:flutter/material.dart";
import "package:mdeal/widgets.dart";

final GlobalKey discardPileKey = GlobalKey();
final GlobalKey listViewKey = GlobalKey();

class AnimationLayer extends StatelessWidget {
  final GlobalKey gkey;
  const AnimationLayer(this.gkey);

  Offset getPosition() {
    final box = gkey.currentContext?.findRenderObject() as RenderBox?;
    final scrollable = listViewKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || scrollable == null) return Offset.zero;
    return box.localToGlobal(Offset.zero, ancestor: scrollable); //this is global position
  }

  @override
  Widget build(BuildContext context) => Positioned(
    left: getPosition().dx,
    top: getPosition().dy,
    child: const SizedBox(
      width: CardWidget.width,
      height: CardWidget.height,
      child: ColoredBox(color: Colors.blue),
    ),
  );
}
