import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/config/feature_flags.dart';
import '../../../../core/constants/cloudinary_config.dart';
import '../../../../core/firestore_create/models/category_document.dart';
import '../../../../core/firestore_create/models/product_document.dart';
import '../../../../core/firestore_create/utils/firestore_create_exception.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../services/cloudinary_service.dart';
import '../../../../widgets/multi_image_picker_widget.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../product/domain/entities/product_image_ref.dart';
import '../providers/admin_providers.dart';

/// Admin feature: Firestore catalog seeding (create categories and products).
class AdminPage extends ConsumerStatefulWidget {
  const AdminPage({super.key});

  @override
  ConsumerState<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends ConsumerState<AdminPage> {
  bool _busy = false;

  /// Firestore category `gender`: `male` | `female` | `both` | `kids`.
  String _categoryGender = 'both';

  final _categoryFormKey = GlobalKey<FormState>();
  late final TextEditingController _categoryIdCtrl;
  late final TextEditingController _categoryNameCtrl;

  final _productFormKey = GlobalKey<FormState>();
  late final TextEditingController _productIdCtrl;
  late final TextEditingController _productNameCtrl;
  late final TextEditingController _productDescriptionCtrl;
  late final TextEditingController _productPriceCtrl;
  late final TextEditingController _productCategoryIdCtrl;

  List<XFile> _productImages = [];

  @override
  void initState() {
    super.initState();
    _categoryIdCtrl = TextEditingController();
    _categoryNameCtrl = TextEditingController();

    _productIdCtrl = TextEditingController();
    _productNameCtrl = TextEditingController();
    _productDescriptionCtrl = TextEditingController();
    _productPriceCtrl = TextEditingController();
    _productCategoryIdCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _categoryIdCtrl.dispose();
    _categoryNameCtrl.dispose();
    _productIdCtrl.dispose();
    _productNameCtrl.dispose();
    _productDescriptionCtrl.dispose();
    _productPriceCtrl.dispose();
    _productCategoryIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  Future<void> _submitCategory() async {
    if (!(_categoryFormKey.currentState?.validate() ?? false)) return;
    final svc = ref.read(firestoreCreateServiceProvider);
    await _run(() async {
      try {
        final id = await svc.createCategory(
          CategoryDocument(
            id: _categoryIdCtrl.text.trim(),
            name: _categoryNameCtrl.text.trim(),
            imageUrl: '',
            gender: _categoryGender,
          ),
        );
        _toast('Category saved (id: $id)');
      } on FirestoreCreateException catch (e) {
        _toast(e.message, error: true);
      } catch (e) {
        _toast('$e', error: true);
      }
    });
  }

  Future<void> _submitProduct() async {
    if (!(_productFormKey.currentState?.validate() ?? false)) return;
    if (_productImages.isEmpty) {
      _toast('Add at least one product image.', error: true);
      return;
    }

    final price = double.parse(
      _productPriceCtrl.text.trim().replaceAll(',', '.'),
    );

    final cloudinary = ref.read(cloudinaryServiceProvider);
    final svc = ref.read(firestoreCreateServiceProvider);

    await _run(() async {
      try {
        final refs = <ProductImageRef>[];
        for (var i = 0; i < _productImages.length; i++) {
          final file = _productImages[i];
          try {
            final up = await cloudinary.uploadImage(
              file,
              folder: CloudinaryConfig.productsUploadFolder,
            );
            refs.add(ProductImageRef(
              imageUrl: up.imageUrl,
              publicId: up.publicId,
            ));
          } on CloudinaryUploadException catch (e) {
            _toast(
              'Image ${i + 1} failed: ${e.message}',
              error: true,
            );
            return;
          } catch (e) {
            _toast('Image ${i + 1} upload failed: $e', error: true);
            return;
          }
        }

        final id = await svc.createProduct(
          ProductDocument(
            id: _productIdCtrl.text.trim(),
            name: _productNameCtrl.text.trim(),
            description: _productDescriptionCtrl.text.trim(),
            price: price,
            categoryId: _productCategoryIdCtrl.text.trim(),
            collectionId: '',
            images: refs,
          ),
        );
        _toast('Product saved (id: $id)');
        setState(() => _productImages = []);
        _productIdCtrl.clear();
        _productNameCtrl.clear();
        _productDescriptionCtrl.clear();
        _productPriceCtrl.clear();
        _productCategoryIdCtrl.clear();
      } on FirestoreCreateException catch (e) {
        _toast(e.message, error: true);
      } catch (e) {
        _toast('$e', error: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!FeatureFlags.enableAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Admin is turned off. Set '
              'FeatureFlags.enableAdminInSource to true in '
              '`lib/core/config/feature_flags.dart`, or build with '
              '`--dart-define=ENABLE_CREATE_MODE=true`.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final auth = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Admin')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Create Firestore documents while signed in. Leave document id '
                'empty to let Firestore assign one. Product images upload to '
                'Cloudinary (unsigned preset), then metadata is saved with a '
                'gallery array.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              auth.when(
                data: (user) {
                  if (user == null) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'You are not signed in. Sign in to create documents.',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: _busy
                                  ? null
                                  : () => Navigator.of(context)
                                      .pushNamed('/login'),
                              child: const Text('Sign in'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.verified_user_outlined),
                          title: const Text('Signed in'),
                          subtitle: Text(user.email ?? user.id),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Form(
                            key: _categoryFormKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'New category',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _categoryIdCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Document id (optional)',
                                    hintText: 'Empty = auto id',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _categoryNameCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Name',
                                    border: OutlineInputBorder(),
                                  ),
                                  textCapitalization: TextCapitalization.words,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Enter a name';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Gender',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                RadioGroup<String>(
                                  groupValue: _categoryGender,
                                  onChanged: (String? value) {
                                    if (_busy || value == null) return;
                                    setState(() => _categoryGender = value);
                                  },
                                  child: Column(
                                    children: [
                                      RadioListTile<String>(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        title: const Text('Both'),
                                        value: 'both',
                                      ),
                                      RadioListTile<String>(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        title: const Text('Kids'),
                                        value: 'kids',
                                      ),
                                      RadioListTile<String>(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        title: const Text('Female'),
                                        value: 'female',
                                      ),
                                      RadioListTile<String>(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        title: const Text('Male'),
                                        value: 'male',
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                FilledButton(
                                  onPressed: _busy ? null : _submitCategory,
                                  child: const Text('Save category'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Form(
                            key: _productFormKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'New product',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _productIdCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Document id (optional)',
                                    hintText: 'Empty = auto id',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _productNameCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Name',
                                    border: OutlineInputBorder(),
                                  ),
                                  textCapitalization: TextCapitalization.words,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Enter a name';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _productDescriptionCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Description',
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _productPriceCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Price',
                                    hintText: 'e.g. 19.99',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[\d.,]'),
                                    ),
                                  ],
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Enter a price';
                                    }
                                    final p = double.tryParse(
                                      v.trim().replaceAll(',', '.'),
                                    );
                                    if (p == null || p < 0) {
                                      return 'Invalid number';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                MultiImagePickerWidget(
                                  label: 'Product images (Cloudinary)',
                                  files: _productImages,
                                  onChanged: (list) =>
                                      setState(() => _productImages = list),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _productCategoryIdCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Category id',
                                    hintText: 'Firestore category document id',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Enter the category document id';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                FilledButton(
                                  onPressed: _busy ? null : _submitProduct,
                                  child: const Text('Upload images & save product'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Use the same id you chose (or that was returned) when '
                        'saving a category as the product’s category id.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => Text('Auth error: $e'),
              ),
            ],
          ),
          if (_busy)
            const ModalBarrier(
              dismissible: false,
              color: Color(0x33000000),
            ),
          if (_busy)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
