# Promises

> [!tldr]
> Four combinators, and one rule about errors: an `await` that rejects behaves exactly like a `throw`, so `try` and `catch` work normally.

---

## The combinators

| | Resolves when | Rejects when |
| --- | --- | --- |
| `Promise.all` | every promise resolves | the first one rejects, immediately, without waiting for the rest |
| `Promise.allSettled` | all of them finish, however they finish | never |
| `Promise.race` | the first one settles, resolved or rejected | the first one settles, if that was a rejection |
| `Promise.any` | the first one resolves | all of them reject |

`Promise.all` also accepts plain values, which it treats as already resolved:

```js
Promise.all([Promise.resolve(3), 42, slowPromise]).then(console.log);
// [3, 42, 'foo']
```

---

## all vs allSettled

```js
try {
  await Promise.all([fetchData(1000), fetchData(5000)]);
} catch (error) {
  console.log(error.message); // fires at 1000ms, not 5000ms
}
```

`Promise.all` gives up the moment anything fails. That is what you want when you need all the results, and wrong when you want to know which ones worked:

```js
const results = await Promise.allSettled([fetchData(), fetchAnotherData()]);

results.forEach((result, index) => {
  if (result.status === 'fulfilled') console.log(index, 'Data:', result.value);
  else console.log(index, 'Error:', result.reason.message);
});
```

> [!warning] allSettled never rejects
> Wrapping it in `try` and `catch` is pointless, and the `catch` block is dead code. Every outcome arrives inside the results array instead.

---

## Errors

```js
async function example() {
  try {
    const data = await fetchData();     // rejects
    console.log(data);                  // skipped
  } catch (error) {
    console.log(error.message);
    throw new Error('Another error');   // replaces the original
  } finally {
    console.log('Finally');             // runs either way
  }
  console.log('End');                   // never reached, we threw
}

example().catch(error => console.log(error.message));
```

Three things worth holding on to. `finally` runs whether you returned, threw, or fell through. Throwing inside `catch` means the caller has to handle it, so the `async` function needs a `.catch` at the call site. And a `return` inside `catch` skips the rest of the function but still runs `finally`.

---

## Not awaiting is a decision

```js
async function example() {
  console.log('Start');
  fetchData().then(console.log).finally(() => console.log('Finally'));
  console.log('End');   // prints before either of the above
}
```

Leaving off `await` means the function does not wait. Sometimes that is what you want. Usually it means an unhandled rejection later, and Node has terminated the process on those since version 15.
