import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:mdeal/view_models.dart";
import "package:mdeal/widgets.dart";
import "package:shared/utils.dart";

class LandingPage extends ReactiveWidget<LandingViewModel> {
  static const monopolyRed = Color(0xfff10600);
  static const monopolyGreen = Color(0xff50a753);
  static const monopolyBlue = Color(0xff74cdf5);

  @override
  LandingViewModel createModel() => LandingViewModel();

  List<Widget> header(BuildContext context) => [
    const SizedBox(height: 32),
    Image.asset("images/banner.png"),
    const SizedBox(height: 12),
    Text("Monopoly Deal and all associated trademarks are the intellectual property of Hasbro Inc. This application is not affiliated or endorsed by them in any way.", style: context.textTheme.labelSmall),
  ];

  @override
  Widget build(BuildContext context, LandingViewModel model) => Scaffold(
    appBar: AppBar(),
    body: Padding(
      padding: const EdgeInsets.all(8),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints.loose(const Size.fromWidth(500)),
          child: Column(
            children: [
              ...header(context),
              const Spacer(),
              Expanded(
                flex: 3,
                child: PageView(
                  controller: model.pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _nameAndUri(context, model),
                    _roomChoice(context, model),
                    _lobby(context, model),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _nameAndUri(BuildContext context, LandingViewModel model) => SingleChildScrollView(
    child: Column(
      children: [
        Text(
          "Enter your name",
          style: context.textTheme.displaySmall,
        ),
        const SizedBox(height: 24),
        textField(
          controller: model.usernameController,
          autocorrect: true,
          capitalization: .words,
          type: .name,
          style: context.textTheme.titleLarge
        ),
        const SizedBox(height: 12),
        if (model.errorText != null)
          Text(model.errorText!, style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 12),
        Align(
          alignment: .bottomRight,
          child: ElevatedButton(
            onPressed: model.canConnect ? model.connect : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: monopolyGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text("Connect"),
          ),
        ),
        // const Spacer(),
        ExpansionTile(
          title: Text("Connecting to: ${model.uri}", style: context.textTheme.labelLarge),
          children: [
            textField(
              controller: model.uriController,
              autofocus: true,
              type: .url,
              hint: "ws://localhost:8040",
              error: model.uriError,
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    ),
  );

  Widget _roomChoice(BuildContext context, LandingViewModel model) => Column(
    children: [
      ElevatedButton(
        onPressed: model.createRoom,
        style: ElevatedButton.styleFrom(
          backgroundColor: monopolyBlue,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          textStyle: context.textTheme.headlineSmall,
        ),
        child: const Text("Create a room"),
      ),
      const SizedBox(height: 24),
      Text(
        "OR",
        style: context.textTheme.displaySmall,
      ),
      const SizedBox(height: 24),
      Text(
        "Enter a room code",
        style: context.textTheme.titleLarge,
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: 150,
        child: textField(
          controller: model.roomController,
          formatter: FilteringTextInputFormatter.digitsOnly,
          hint: "0001-9999",
          type: const .numberWithOptions(signed: false, decimal: false),
          style: context.textTheme.titleLarge,
        ),
      ),
      const SizedBox(height: 12),
      if (model.roomError != null)
        Text(model.roomError!, style: const TextStyle(color: Colors.red)),
      const Spacer(),
      Row(
        children: [
          TextButton(
            onPressed: model.backToName,
            child: const Text("Back"),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: model.joinRoom,
            style: ElevatedButton.styleFrom(backgroundColor: monopolyGreen, foregroundColor: Colors.white),
            child: const Text("Join"),
          ),
        ],
      ),
      const SizedBox(height: 12),
    ],
  );

  Widget _lobby(BuildContext context, LandingViewModel model) => Column(
    children: [
      Text("Room #${model.roomCode}", style: context.textTheme.headlineSmall),
      const SizedBox(height: 16),
      const Divider(),
      if (model.users.length > 1)
        Text("Waiting for ${model.unreadyCount} more players to ready up...")
      else
        const Text("Waiting for more players..."),
      for (final (user, isReady) in model.users.records)
        ListTile(
          title: Text(user),
          trailing: isReady
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.pending),
        ),
      const Spacer(),
      Row(
        children: [
          TextButton(
            onPressed: model.backToName,
            child: const Text("Back"),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: model.toggleReady,
            style: model.isReady
              ? ElevatedButton.styleFrom(backgroundColor: monopolyRed, foregroundColor: Colors.white)
              : ElevatedButton.styleFrom(backgroundColor: monopolyGreen, foregroundColor: Colors.white),
            child: model.isReady ? const Text("Not Ready") : const Text("Ready"),
          ),
        ],
      ),
      const SizedBox(height: 12),
    ],
  );
}

Widget textField({
  required TextEditingController controller,
  TextInputType? type,
  TextInputAction? action = .done,
  bool autocorrect = false,
  bool autofocus = false,
  TextCapitalization? capitalization = .none,
  TextInputFormatter? formatter,
  String? hint,
  String? error,
  TextStyle? style,
}) => TextField(
  controller: controller,
  autocorrect: autocorrect,
  enableSuggestions: autocorrect,
  keyboardType: type,
  textInputAction: action,
  style: style,
  autofocus: autofocus,
  textAlign: .center,
  decoration: InputDecoration(
    border: const OutlineInputBorder(),
    hintText: hint,
    errorText: error,
  ),
);
