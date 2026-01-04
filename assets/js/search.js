
document.addEventListener("DOMContentLoaded", function () {
  const searchQuery = document.getElementById("search-query");
  const searchResults = document.getElementById("search-results");
  const searchResultsContainer = document.getElementById("search-results-container");

  let fuse;
  let searchIndex;

  // Debounce function
  function debounce(func, wait) {
    let timeout;
    return function (...args) {
      const context = this;
      clearTimeout(timeout);
      timeout = setTimeout(() => func.apply(context, args), wait);
    };
  }

  // Fetch the search index
  fetch("/index.json")
    .then((response) => response.json())
    .then((data) => {
      searchIndex = data;
      fuse = new Fuse(searchIndex, {
        keys: ["title", "content"],
        includeScore: true,
        threshold: 0.4,
      });
      // Add event listener only after Fuse is initialized
      searchQuery.addEventListener("input", performSearch);
    })
    .catch((error) => console.error("Error fetching search index:", error));

  // Perform search
  const performSearch = debounce(() => {
    const query = searchQuery.value;
    if (query.length < 2) {
      searchResults.innerHTML = "";
      searchResultsContainer.classList.remove("show");
      return;
    }

    const results = fuse.search(query);
    displayResults(results);
  }, 300);

  // Display results
  function displayResults(results) {
    searchResults.innerHTML = "";
    if (results.length > 0) {
      searchResultsContainer.classList.add("show");
      results.forEach(({ item }) => {
        const li = document.createElement("li");
        const a = document.createElement("a");
        a.href = item.url;
        a.textContent = item.title;
        li.appendChild(a);
        searchResults.appendChild(li);
      });
      // Highlight results
      const markInstance = new Mark(document.querySelector("main"));
      markInstance.unmark({
        done: () => {
          results.forEach(({ item }) => {
            markInstance.mark(item.title);
          });
        },
      });
    } else {
      searchResultsContainer.classList.remove("show");
      // Unmark results
      const markInstance = new Mark(document.querySelector("main"));
      markInstance.unmark();
    }
  }
});
