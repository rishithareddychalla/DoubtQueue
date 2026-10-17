import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'state_views.dart';

class CreateSessionCard extends StatefulWidget {
  const CreateSessionCard({super.key, required this.onCreate});

  final Future<void> Function(String title, String mentorName) onCreate;

  @override
  State<CreateSessionCard> createState() => _CreateSessionCardState();
}

class _CreateSessionCardState extends State<CreateSessionCard> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _mentorName = TextEditingController();
  bool _creating = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _title.dispose();
    _mentorName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _creating = true;
      _error = null;
      _success = null;
    });

    try {
      await widget.onCreate(_title.text.trim(), _mentorName.text.trim());
      if (!mounted) return;
      _formKey.currentState!.reset();
      setState(() => _success = 'Session created. It is selected below.');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
    if (!mounted) return;
    setState(() => _creating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.add_to_photos_rounded,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start a session',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                        ),
                        Text(
                          'Create a queue for students to join',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _title,
                maxLength: 255,
                buildCounter: (
                  context, {
                  required currentLength,
                  required isFocused,
                  maxLength,
                }) => null,
                decoration: const InputDecoration(
                  labelText: 'Session title',
                  hintText: 'For example: PHP Basics Doubt Session',
                  prefixIcon: Icon(Icons.title),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) => _required(value, 'Enter a session title'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mentorName,
                maxLength: 255,
                buildCounter: (
                  context, {
                  required currentLength,
                  required isFocused,
                  maxLength,
                }) => null,
                decoration: const InputDecoration(
                  labelText: 'Mentor name',
                  hintText: 'For example: Priya',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) => _required(value, 'Enter your name'),
              ),
              if (_error != null) ...[
                const SizedBox(height: itemGap),
                ErrorBanner(message: _error!),
              ],
              if (_success != null) ...[
                const SizedBox(height: itemGap),
                SuccessBanner(message: _success!),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _creating ? null : _submit,
                  icon: _creating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add),
                  label: Text(_creating ? 'Creating...' : 'Start session'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _required(String? value, String message) {
    return value == null || value.trim().isEmpty ? message : null;
  }
}
