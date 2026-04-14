import '../constants/app_constants.dart';

class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult.valid()
      : isValid = true,
        errorMessage = null;

  const ValidationResult.invalid(this.errorMessage) : isValid = false;
}

class Validators {
  // Phone Number Validation
  static ValidationResult validatePhone(String phone) {
    if (phone.isEmpty) {
      return const ValidationResult.invalid('Phone number is required');
    }

    final regex = RegExp(AppConstants.phoneRegex);
    if (!regex.hasMatch(phone)) {
      return const ValidationResult.invalid(
          'Enter a valid Pakistani phone number');
    }

    return const ValidationResult.valid();
  }

  static ValidationResult validatePhoneDigits(String digits) {
    if (digits.isEmpty) {
      return const ValidationResult.invalid('Phone number is required');
    }

    if (digits.length != 10) {
      return const ValidationResult.invalid('Enter 10 digits after +92');
    }

    if (!digits.startsWith('3')) {
      return const ValidationResult.invalid('Phone number must start with 3');
    }

    return const ValidationResult.valid();
  }

  // Email Validation
  static ValidationResult validateEmail(String email) {
    final normalized = email.trim().toLowerCase();

    if (normalized.isEmpty) {
      return const ValidationResult.invalid('Email is required');
    }

    if (normalized.contains('..')) {
      return const ValidationResult.invalid(
          'Email cannot contain consecutive dots');
    }

    final parts = normalized.split('@');
    if (parts.length != 2) {
      return const ValidationResult.invalid('Enter a valid email address');
    }

    final localPart = parts[0];
    final domainPart = parts[1];

    if (localPart.isEmpty ||
        localPart.startsWith('.') ||
        localPart.endsWith('.')) {
      return const ValidationResult.invalid('Enter a valid email address');
    }

    if (domainPart.isEmpty ||
        domainPart.startsWith('-') ||
        domainPart.endsWith('-') ||
        !domainPart.contains('.')) {
      return const ValidationResult.invalid('Enter a valid email domain');
    }

    final regex = RegExp(AppConstants.emailRegex);
    if (!regex.hasMatch(normalized)) {
      return const ValidationResult.invalid('Enter a valid email address');
    }

    return const ValidationResult.valid();
  }

  // Password Validation
  static ValidationResult validatePassword(String password) {
    if (password.isEmpty) {
      return const ValidationResult.invalid('Password is required');
    }

    if (password.length < AppConstants.minPasswordLength) {
      return const ValidationResult.invalid(
        'Password must be at least ${AppConstants.minPasswordLength} characters',
      );
    }

    if (password.length > AppConstants.maxPasswordLength) {
      return const ValidationResult.invalid(
        'Password must not exceed ${AppConstants.maxPasswordLength} characters',
      );
    }

    if (password.contains(RegExp(r'\s'))) {
      return const ValidationResult.invalid(
        'Password must not contain spaces',
      );
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return const ValidationResult.invalid(
        'Password must include at least one uppercase letter',
      );
    }

    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return const ValidationResult.invalid(
        'Password must include at least one lowercase letter',
      );
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return const ValidationResult.invalid(
        'Password must include at least one number',
      );
    }

    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      return const ValidationResult.invalid(
        'Password must include at least one special character',
      );
    }

    return const ValidationResult.valid();
  }

  static ValidationResult validateSignInPassword(String password) {
    if (password.isEmpty) {
      return const ValidationResult.invalid('Password is required');
    }

    if (password.length > AppConstants.maxPasswordLength) {
      return const ValidationResult.invalid(
        'Password must not exceed ${AppConstants.maxPasswordLength} characters',
      );
    }

    return const ValidationResult.valid();
  }

  static ValidationResult validateConfirmPassword(
      String password, String confirmPassword) {
    if (confirmPassword.isEmpty) {
      return const ValidationResult.invalid('Please confirm your password');
    }

    if (password != confirmPassword) {
      return const ValidationResult.invalid('Passwords do not match');
    }

    return const ValidationResult.valid();
  }

  // Name Validation
  static ValidationResult validateName(String name) {
    if (name.isEmpty) {
      return const ValidationResult.invalid('Name is required');
    }

    if (name.length < 2) {
      return const ValidationResult.invalid(
          'Name must be at least 2 characters');
    }

    if (name.length > 50) {
      return const ValidationResult.invalid(
          'Name must not exceed 50 characters');
    }

    return const ValidationResult.valid();
  }

  // Bio Validation
  static ValidationResult validateBio(String bio) {
    if (bio.isEmpty) {
      return const ValidationResult.invalid('Bio is required');
    }

    if (bio.length < 20) {
      return const ValidationResult.invalid(
          'Bio must be at least 20 characters');
    }

    if (bio.length > AppConstants.maxBioLength) {
      return const ValidationResult.invalid(
        'Bio must not exceed ${AppConstants.maxBioLength} characters',
      );
    }

    return const ValidationResult.valid();
  }

  // Service Title Validation
  static ValidationResult validateServiceTitle(String title) {
    if (title.isEmpty) {
      return const ValidationResult.invalid('Service title is required');
    }

    if (title.length < 5) {
      return const ValidationResult.invalid(
          'Title must be at least 5 characters');
    }

    if (title.length > AppConstants.maxServiceTitleLength) {
      return const ValidationResult.invalid(
        'Title must not exceed ${AppConstants.maxServiceTitleLength} characters',
      );
    }

    return const ValidationResult.valid();
  }

  // Description Validation
  static ValidationResult validateDescription(String description) {
    if (description.isEmpty) {
      return const ValidationResult.invalid('Description is required');
    }

    if (description.length < 20) {
      return const ValidationResult.invalid(
          'Description must be at least 20 characters');
    }

    if (description.length > AppConstants.maxDescriptionLength) {
      return const ValidationResult.invalid(
        'Description must not exceed ${AppConstants.maxDescriptionLength} characters',
      );
    }

    return const ValidationResult.valid();
  }

  // Issue Title Validation
  static ValidationResult validateIssueTitle(String title) {
    if (title.isEmpty) {
      return const ValidationResult.invalid('Issue title is required');
    }

    if (title.length < 5) {
      return const ValidationResult.invalid(
          'Title must be at least 5 characters');
    }

    if (title.length > AppConstants.maxIssueTitleLength) {
      return const ValidationResult.invalid(
        'Title must not exceed ${AppConstants.maxIssueTitleLength} characters',
      );
    }

    return const ValidationResult.valid();
  }

  // Issue Description Validation
  static ValidationResult validateIssueDescription(String description) {
    if (description.isEmpty) {
      return const ValidationResult.invalid('Please describe your issue');
    }

    if (description.length < 10) {
      return const ValidationResult.invalid(
          'Description must be at least 10 characters');
    }

    if (description.length > AppConstants.maxIssueDescriptionLength) {
      return const ValidationResult.invalid(
        'Description must not exceed ${AppConstants.maxIssueDescriptionLength} characters',
      );
    }

    return const ValidationResult.valid();
  }

  // Address Validation
  static ValidationResult validateAddress(String address) {
    if (address.isEmpty) {
      return const ValidationResult.invalid('Address is required');
    }

    if (address.length < 10) {
      return const ValidationResult.invalid('Please enter a complete address');
    }

    if (address.length > 200) {
      return const ValidationResult.invalid(
          'Address must not exceed 200 characters');
    }

    return const ValidationResult.valid();
  }

  // Price Validation
  static ValidationResult validateFixedPrice(String price) {
    if (price.isEmpty) {
      return const ValidationResult.invalid('Price is required');
    }

    final amount = int.tryParse(price.replaceAll(',', ''));
    if (amount == null) {
      return const ValidationResult.invalid('Enter a valid amount');
    }

    if (amount < AppConstants.minFixedPrice) {
      return const ValidationResult.invalid(
        'Price must be at least ${AppConstants.currencySymbol} ${AppConstants.minFixedPrice}',
      );
    }

    if (amount > AppConstants.maxFixedPrice) {
      return const ValidationResult.invalid(
        'Price must not exceed ${AppConstants.currencySymbol} ${AppConstants.maxFixedPrice}',
      );
    }

    return const ValidationResult.valid();
  }

  static ValidationResult validateHourlyRate(String rate) {
    if (rate.isEmpty) {
      return const ValidationResult.invalid('Hourly rate is required');
    }

    final amount = int.tryParse(rate.replaceAll(',', ''));
    if (amount == null) {
      return const ValidationResult.invalid('Enter a valid amount');
    }

    if (amount < AppConstants.minHourlyRate) {
      return const ValidationResult.invalid(
        'Rate must be at least ${AppConstants.currencySymbol} ${AppConstants.minHourlyRate}/hr',
      );
    }

    if (amount > AppConstants.maxHourlyRate) {
      return const ValidationResult.invalid(
        'Rate must not exceed ${AppConstants.currencySymbol} ${AppConstants.maxHourlyRate}/hr',
      );
    }

    return const ValidationResult.valid();
  }

  // Quote Amount Validation
  static ValidationResult validateQuoteAmount(String amount) {
    if (amount.isEmpty) {
      return const ValidationResult.invalid('Quote amount is required');
    }

    final value = int.tryParse(amount.replaceAll(',', ''));
    if (value == null) {
      return const ValidationResult.invalid('Enter a valid amount');
    }

    if (value <= 0) {
      return const ValidationResult.invalid('Quote must be greater than 0');
    }

    if (value > AppConstants.maxFixedPrice) {
      return const ValidationResult.invalid(
        'Quote must not exceed ${AppConstants.currencySymbol} ${AppConstants.maxFixedPrice}',
      );
    }

    return const ValidationResult.valid();
  }

  // Review Comment Validation
  static ValidationResult validateReviewComment(String comment) {
    if (comment.length > AppConstants.maxCommentLength) {
      return const ValidationResult.invalid(
        'Comment must not exceed ${AppConstants.maxCommentLength} characters',
      );
    }

    return const ValidationResult.valid();
  }

  // Provider Note Validation
  static ValidationResult validateProviderNote(String note) {
    if (note.length > AppConstants.maxProviderNoteLength) {
      return const ValidationResult.invalid(
        'Note must not exceed ${AppConstants.maxProviderNoteLength} characters',
      );
    }

    return const ValidationResult.valid();
  }

  // Quote Message Validation
  static ValidationResult validateQuoteMessage(String message) {
    if (message.length > AppConstants.maxQuoteMessageLength) {
      return const ValidationResult.invalid(
        'Message must not exceed ${AppConstants.maxQuoteMessageLength} characters',
      );
    }

    return const ValidationResult.valid();
  }

  // Dispute Description Validation
  static ValidationResult validateDisputeDescription(String description) {
    if (description.isEmpty) {
      return const ValidationResult.invalid('Please describe the issue');
    }

    if (description.length < 30) {
      return const ValidationResult.invalid(
          'Description must be at least 30 characters');
    }

    if (description.length > 500) {
      return const ValidationResult.invalid(
          'Description must not exceed 500 characters');
    }

    return const ValidationResult.valid();
  }

  // Top-up Amount Validation
  static ValidationResult validateTopUpAmount(String amount) {
    if (amount.isEmpty) {
      return const ValidationResult.invalid('Amount is required');
    }

    final value = int.tryParse(amount.replaceAll(',', ''));
    if (value == null) {
      return const ValidationResult.invalid('Enter a valid amount');
    }

    if (value < AppConstants.minTopUpAmount) {
      return const ValidationResult.invalid(
        'Minimum top-up is ${AppConstants.currencySymbol} ${AppConstants.minTopUpAmount}',
      );
    }

    if (value > AppConstants.maxTopUpAmount) {
      return const ValidationResult.invalid(
        'Maximum top-up is ${AppConstants.currencySymbol} ${AppConstants.maxTopUpAmount}',
      );
    }

    return const ValidationResult.valid();
  }

  // Tags Validation
  static ValidationResult validateTags(List<String> tags) {
    if (tags.isEmpty) {
      return const ValidationResult.valid();
    }

    if (tags.length > AppConstants.maxTags) {
      return const ValidationResult.invalid(
        'Maximum ${AppConstants.maxTags} tags allowed',
      );
    }

    for (final tag in tags) {
      if (tag.length > 20) {
        return const ValidationResult.invalid(
            'Each tag must not exceed 20 characters');
      }
    }

    return const ValidationResult.valid();
  }

  // Skills Validation
  static ValidationResult validateSkills(List<String> skills) {
    if (skills.isEmpty) {
      return const ValidationResult.invalid('Select at least one skill');
    }

    return const ValidationResult.valid();
  }

  // Cities Validation
  static ValidationResult validateCities(List<String> cities) {
    if (cities.isEmpty) {
      return const ValidationResult.invalid('Select at least one service city');
    }

    return const ValidationResult.valid();
  }
}

extension ValidationResultExtension on ValidationResult {
  String? get error => isValid ? null : errorMessage;
}
