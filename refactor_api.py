import re

with open('lib/services/api_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

helper_func = '''
  String _extractDioErrorMsg(DioException e, String defaultMsg) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Network error occurred. Please check your connection.';
    }
    final data = e.response?.data;
    if (data != null) {
      if (data is String) {
        if (data.contains('ERR_NGROK')) {
          return 'The endpoint is offline or unavailable. Please check the server.';
        }
        if (data.contains('<html')) {
          return f"{defaultMsg} (Server Error {e.response?.statusCode})";
        }
        return data.strip();
      } else if (data is dict) { # Not dict, in dart it's map
        pass
      }
    }
    return defaultMsg;
  }
'''
helper_func_dart = '''
  String _extractDioErrorMsg(DioException e, String defaultMsg) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Network error occurred. Please check your connection.';
    }
    final data = e.response?.data;
    if (data != null) {
      if (data is String) {
        if (data.contains('ERR_NGROK')) {
          return 'The endpoint is offline or unavailable. Please check the server.';
        }
        if (data.contains('<html')) {
          return '$defaultMsg (Server Error ${e.response?.statusCode})';
        }
        return data.trim();
      } else if (data is Map<String, dynamic>) {
        return data['detail'] ?? data['message'] ?? data['error'] ?? data.toString();
      } else if (data is List) {
        return data.join('\\n');
      }
    }
    return defaultMsg;
  }
'''

if '_extractDioErrorMsg' not in content:
    content = content.replace('class ApiService {', 'class ApiService {\\n' + helper_func_dart)

# We need to replace catch blocks exactly
def replacer(match):
    body = match.group(1)
    
    # Try to find default message
    default_msg = "'Network error occurred'"
    
    # look for String msg = '...';
    msg_match = re.search(r"String msg\s*=\s*'([^']+)'", body)
    if msg_match:
        default_msg = "'" + msg_match.group(1) + "'"
    
    # look for throw Exception('Error fetching...')
    exc_match = re.search(r"throw Exception\('([^']+)'\)", match.group(0))
    if exc_match and "msg" not in exc_match.group(1):
        # like 'Error fetching dashboard: ${e.message}'
        # we extract just the string before the colon
        s = exc_match.group(1).split(':')[0]
        default_msg = "'" + s + "'"
        
    return f"    }} on DioException catch (e) {{\n      throw Exception(_extractDioErrorMsg(e, {default_msg}));\n    }}"

# Regex to match the entire `} on DioException catch (e) { ... }` block
pattern = re.compile(r'    \} on DioException catch \(e\) \{(.*?)\}', re.DOTALL)

new_content = pattern.sub(replacer, content)

with open('lib/services/api_service.dart', 'w', encoding='utf-8') as f:
    f.write(new_content)

print("Refactoring complete.")
