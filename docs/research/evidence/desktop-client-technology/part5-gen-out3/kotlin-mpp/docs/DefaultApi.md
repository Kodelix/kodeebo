# DefaultApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------------- | ------------- | ------------- |
| [**getSession**](DefaultApi.md#getSession) | **GET** /v1/sessions/{id} |  |


<a id="getSession"></a>
# **getSession**
> Session getSession(id)



### Example
```kotlin
// Import classes:
//import sample.api.infrastructure.*
//import sample.api.models.*

val apiInstance = DefaultApi()
val id : kotlin.String = 38400000-8cf0-11bd-b23e-10b96e4ef00d // kotlin.String | 
try {
    val result : Session = apiInstance.getSession(id)
    println(result)
} catch (e: ClientException) {
    println("4xx response calling DefaultApi#getSession")
    e.printStackTrace()
} catch (e: ServerException) {
    println("5xx response calling DefaultApi#getSession")
    e.printStackTrace()
}
```

### Parameters
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **id** | **kotlin.String**|  | |

### Return type

[**Session**](Session.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

