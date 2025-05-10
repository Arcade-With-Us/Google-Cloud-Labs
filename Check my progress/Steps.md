### Those who don't get Check My Progress Bar automatically in every lab please implement these steps:

1. First Save this website as a `bookmark` by clicking the **star button** on the `right side of the website bar`: [Click](https://www.cloudskillsboost.google/)
2. Save this above bookmark and pin it in `bookmarks bar` by typing **`Ctrl + Shift + B`**
3. Now on the bookmarks bar right click on the bookmark that you have previously pinned in your bookmarks bar


## Bookmark Code 

```javascript
javascript:(function () {
    const removeLearboard = document.querySelector('.js-lab-leaderboard');
    const showScore = document.querySelector('.games-labs');

    removeLearboard.remove();
    showScore.className = "lab-show l-full no-nav application-new lab-show l-full no-nav "
})();
```
