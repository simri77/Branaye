import '../core/models/note.dart';
import '../core/theme/app_colors.dart';

class MockNoteRepository {
  Future<List<Note>> getAll() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return [
      Note(
        id: '1',
        title: 'Project Branaye Vision',
        content:
            'Redefining the digital paper experience. Minimalist, tactile, and extremely fast. Focus on 8px grids and Material 3 tonal layering for the next sprint.',
        category: 'Ideas',
        color: AppColors.noteWashIdeas,
        isPinned: true,
        createdAt: DateTime(2026, 8, 18),
        tags: ['entrepreneurship', 'growth'],
      ),
      Note(
        id: '2',
        title: 'Q4 Strategy Prep',
        content:
            'Review current growth metrics and prepare slides for the stakeholder meeting on Monday.',
        category: 'Work',
        color: AppColors.noteWashWork,
        createdAt: DateTime(2026, 8, 18),
        tags: ['planning', 'presentation'],
      ),
      Note(
        id: '3',
        title: 'Grocery List',
        content: 'Avocados, Sourdough bread, Almond milk, Fresh basil, Cherry tomatoes.',
        category: 'Personal',
        color: AppColors.noteWashPersonal,
        createdAt: DateTime(2026, 8, 18),
        tags: ['shopping', 'food'],
      ),
      Note(
        id: '4',
        title: 'Linear Algebra II',
        content:
            'Eigenvalues and Eigenvectors: Notes on transformation matrices and their applications in computer graphics.',
        category: 'Study',
        color: AppColors.noteWashStudy,
        createdAt: DateTime(2026, 8, 18),
        tags: ['math', 'coding'],
      ),
      Note(
        id: '5',
        title: 'App Interaction Ideas',
        content:
            'Fluid spring animations for all button states. Taptic feedback for successful save actions.',
        category: 'Ideas',
        color: AppColors.noteWashIdeas,
        createdAt: DateTime(2026, 8, 18),
        tags: ['design', 'ux'],
      ),
      Note(
        id: '6',
        title: 'Weekly Sync',
        content:
            'The engineering team mentioned a delay in the database migration. Need to sync with Sarah.',
        category: 'Work',
        color: AppColors.noteWashWork,
        createdAt: DateTime(2026, 8, 18),
        tags: ['team', 'meetings'],
      ),
    ];
  }
}
