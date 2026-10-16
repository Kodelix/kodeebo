
# Session


## Properties

Name | Type
------------ | -------------
`id` | string
`state` | string
`amountMinor` | number
`startedAt` | Date
`payment` | [SessionPayment](SessionPayment.md)

## Example

```typescript
import type { Session } from ''

// TODO: Update the object below with actual values
const example = {
  "id": null,
  "state": null,
  "amountMinor": null,
  "startedAt": null,
  "payment": null,
} satisfies Session

console.log(example)

// Convert the instance to a JSON string
const exampleJSON: string = JSON.stringify(example)
console.log(exampleJSON)

// Parse the JSON string back to an object
const exampleParsed = JSON.parse(exampleJSON) as Session
console.log(exampleParsed)
```

[[Back to top]](#) [[Back to API list]](../README.md#api-endpoints) [[Back to Model list]](../README.md#models) [[Back to README]](../README.md)


