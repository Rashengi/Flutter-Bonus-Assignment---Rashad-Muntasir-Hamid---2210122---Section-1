class CustomValidators {
  static String? validateDescreption(String? value) {
    if (value == null || value.isEmpty) {
      return "This field is required";
    } else if (value.length < 10) {
      return "Description must be at least 10 characters long";
    } else if (value.length > 200) {
      return "Description must be less than 200 characters long";
    }
    return null;
  }

  static String? validateTitle(String? value) {
    if (value == null || value.isEmpty) {
      return "This field is required";
    } else if (value.length < 3) {
      return "Title must be at least 3 characters long";
    } else if (value.length > 20) {
      return "Title must be less than 20 characters long";
    }
    return null;
  }

  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return "This field is required";
    } else if (double.tryParse(value) == null) {
      return "Please enter a valid number";
    } else if (double.parse(value) <= 0) {
      return "Amount must be greater than 0";
    }
    return null;
  }
}
