import 'package:flutter/material.dart';
import 'package:house_rental/core/widgets/glass_container.dart';
import 'package:house_rental/features/listings/domain/entities/listing_entity.dart';
import 'package:house_rental/features/ai_services/data/property_chat_service.dart';

class AIAssistantSheet extends StatefulWidget {
  final ListingEntity listing;

  const AIAssistantSheet({super.key, required this.listing});

  @override
  State<AIAssistantSheet> createState() => _AIAssistantSheetState();
}

class _AIAssistantSheetState extends State<AIAssistantSheet> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _loading = false;
  final _chatService = PropertyChatService();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _askAI() async {
    if (_controller.text.trim().isEmpty) return;

    final question = _controller.text.trim();
    _controller.clear();

    setState(() {
      _messages.add({'role': 'user', 'text': question});
      _loading = true;
    });

    try {
      final reply = await _chatService.askAboutProperty(
        question: question,
        title: widget.listing.title,
        description: widget.listing.description,
        price: widget.listing.price,
        city: widget.listing.city,
        bedrooms: widget.listing.bedrooms,
        bathrooms: widget.listing.bathrooms,
        sqft: widget.listing.sqft,
      );

      setState(() {
        _messages.add({'role': 'ai', 'text': reply});
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'ai',
          'text': 'Sorry, I encountered an error. Please try again.'
        });
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return GlassContainer.standard(
      context: context,
      borderRadius: 30, // Higher top radius in implementation maybe, but let's keep it consistent
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(Icons.auto_awesome_rounded, color: primaryColor, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                "Nestora AI",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Messages
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded,
                              size: 60, color: Theme.of(context).hintColor.withOpacity(0.2)),
                          const SizedBox(height: 20),
                          const Text(
                            'Ask me anything!',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'AI-powered insights about this home.',
                            style: TextStyle(color: Theme.of(context).hintColor.withOpacity(0.6), fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 32),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            alignment: WrapAlignment.center,
                            children: [
                              _SuggestedQuestion(
                                text: 'Price Analysis',
                                onTap: () {
                                  _controller.text = 'Is this price reasonable for the area?';
                                  _askAI();
                                },
                              ),
                              _SuggestedQuestion(
                                text: 'Area Info',
                                onTap: () {
                                  _controller.text = 'Tell me about the neighborhood.';
                                  _askAI();
                                },
                              ),
                              _SuggestedQuestion(
                                text: 'Key Features',
                                onTap: () {
                                  _controller.text = 'What are the standout features?';
                                  _askAI();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: _messages.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isUser = message['role'] == 'user';
                      return _MessageBubble(
                        text: message['text']!,
                        isUser: isUser,
                      );
                    },
                  ),
          ),

          if (_loading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                   SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Thinking...',
                    style: TextStyle(color: Theme.of(context).hintColor.withOpacity(0.6), fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // Input
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: GlassContainer.standard(
                    context: context,
                    padding: EdgeInsets.zero,
                    borderRadius: 24,
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        hintStyle: TextStyle(color: Theme.of(context).hintColor.withOpacity(0.4)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _askAI(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _loading ? null : _askAI,
                  child: Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 10, spreadRadius: 1),
                      ],
                    ),
                    child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 28),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const _MessageBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome_rounded, size: 14, color: primaryColor),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: GlassContainer.standard(
              context: context,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              borderRadius: 20,
              child: Text(
                text,
                style: TextStyle(
                  color: isUser ? primaryColor : null,
                  fontWeight: isUser ? FontWeight.w900 : FontWeight.w600,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _SuggestedQuestion extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _SuggestedQuestion({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: GlassContainer.standard(
        context: context,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        borderRadius: 15,
        child: Text(
          text,
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
