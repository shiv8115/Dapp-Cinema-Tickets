//SPDX-License-Identifier:MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title DappCinemas
 * @dev A smart contract for movie management, showtime scheduling, ticket booking, and revenue tracking.
 */
contract DappCinemas is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _totalMovies;
    Counters.Counter private _totalTickets;
    Counters.Counter private _totalSlots;

    struct MovieStruct {
        uint256 id;
        string name;
        string imageUrl;
        string genre;
        string description;
        uint256 timestamp;
        bool deleted;
    }

    struct TicketStruct {
        uint256 id;
        uint256 movieId;
        uint256 slotId;
        address owner;
        uint256 cost;
        uint256 timestamp;
        uint256 day;
        bool refunded;
    }

    // Structure representing a time slot for a movie
    struct TimeSlotStruct {
        uint256 id;
        uint256 movieId;
        uint256 ticketCost;
        uint256 startTime;
        uint256 endTime;
        uint256 capacity;
        uint256 seats;
        bool deleted;
        bool completed;
        uint256 day;
        uint256 balance;
    }

    event Action(string actionType);

    uint256 public balance;
    // Mapping to store the existence of movies
    mapping(uint256 => bool) movieExists;
    mapping(uint256 => MovieStruct) movies;
    // Mapping to store movie time slots
    mapping(uint256 => TimeSlotStruct) movieTimeSlot;
    // Mapping to store ticket holders for each time slot
    mapping(uint256 => mapping(uint256 => address[])) ticketHolder;

    /**
     * @dev Adds a new movie to the system.
     * @param name The name of the movie.
     * @param imageUrl The URL of the movie's image.
     * @param genre The genre of the movie.
     * @param description A brief description of the movie.
     */
    function addMovie(
        string memory name,
        string memory imageUrl,
        string memory genre,
        string memory description
    ) public onlyOwner {
        require(bytes(name).length > 0, "Movie name required");
        require(bytes(imageUrl).length > 0, "Movie image url required");
        require(bytes(genre).length > 0, "Movie genre required");
        require(bytes(description).length > 0, "Movie description required");

        _totalMovies.increment();
        MovieStruct memory movie;

        movie.id = _totalMovies.current();
        movie.name = name;
        movie.imageUrl = imageUrl;
        movie.genre = genre;
        movie.description = description;
        movie.timestamp = currentTime();

        movies[movie.id] = movie;
        movieExists[movie.id] = true;

        emit Action("Movie added successfully");
    }

    /**
     * @dev Updates an existing movie in the system.
     * @param movieId The ID of the movie to be updated.
     * @param name The updated name of the movie.
     * @param imageUrl The updated URL of the movie's image.
     * @param genre The updated genre of the movie.
     * @param description The updated description of the movie.
     */
    function updateMovie(
        uint256 movieId,
        string memory name,
        string memory imageUrl,
        string memory genre,
        string memory description
    ) public onlyOwner {
        require(movieExists[movieId], "Movie doesn't exist!");
        require(bytes(name).length > 0, "Movie name required");
        require(bytes(imageUrl).length > 0, "Movie image URL required");
        require(bytes(genre).length > 0, "Movie genre required");
        require(bytes(description).length > 0, "Movie description required");

        for (uint256 slotId = 1; slotId <= _totalSlots.current(); slotId++) {
            address[] storage holders = ticketHolder[movieId][slotId];
            require(
                holders.length == 0,
                "Cannot update movie with purchased tickets"
            );
        }

        movies[movieId].name = name;
        movies[movieId].imageUrl = imageUrl;
        movies[movieId].genre = genre;
        movies[movieId].description = description;

        emit Action("Movie updated successfully");
    }

    /**
     * @dev Deletes a movie from the system.
     * @param movieId The ID of the movie to be deleted.
     */
    function deleteMovie(uint256 movieId) public onlyOwner {
        require(movieExists[movieId], "Movie doesn't exist!");

        for (uint256 slotId = 1; slotId <= _totalSlots.current(); slotId++) {
            address[] memory holders = ticketHolder[movieId][slotId];
            require(
                holders.length == 0,
                "Cannot delete movie with purchased tickets"
            );
        }

        movies[movieId].deleted = true;
        movieExists[movieId] = false;
    }

    /**
     * @dev Retrieves all available movies in the system.
     * @return Movies An array of MovieStruct representing the available movies.
     */
    function getMovies() public view returns (MovieStruct[] memory Movies) {
        uint256 totalMovies;
        for (uint256 i = 1; i <= _totalMovies.current(); i++) {
            if (!movies[i].deleted) totalMovies++;
        }

        Movies = new MovieStruct[](totalMovies);

        uint256 j = 0;
        for (uint256 i = 1; i <= _totalMovies.current(); i++) {
            if (!movies[i].deleted) {
                Movies[j] = movies[i];
                j++;
            }
        }
    }

    /**
     * @dev Retrieves the details of a specific movie.
     * @param id The ID of the movie.
     * @return MovieStruct The MovieStruct representing the movie with the given ID.
     */
    function getMovie(uint256 id) public view returns (MovieStruct memory) {
        return movies[id];
    }

    /**
     * @dev Adds multiple timeslots for a movie.
     * @param movieId The ID of the movie.
     * @param ticketCosts An array of ticket costs for each timeslot.
     * @param startTimes An array of start times for each timeslot.
     * @param endTimes An array of end times for each timeslot.
     * @param capacities An array of capacities (seats available) for each timeslot.
     * @param viewingDays An array of viewing days for each timeslot.
     */
    function addTimeslot(
        uint256 movieId,
        uint256[] memory ticketCosts,
        uint256[] memory startTimes,
        uint256[] memory endTimes,
        uint256[] memory capacities,
        uint256[] memory viewingDays
    ) public onlyOwner {
        require(movieExists[movieId], "Movie not found");
        require(ticketCosts.length > 0, "Tickets cost must not be empty");
        require(capacities.length > 0, "Capacities must not be empty");
        require(startTimes.length > 0, "Start times cost must not be empty");
        require(endTimes.length > 0, "End times cost must not be empty");
        require(viewingDays.length > 0, "Viewing days must not be empty");
        require(
            ticketCosts.length == viewingDays.length &&
                viewingDays.length == capacities.length &&
                capacities.length == startTimes.length &&
                startTimes.length == endTimes.length &&
                endTimes.length == viewingDays.length,
            "All parameters must have equal array length"
        );

        for (uint i = 0; i < viewingDays.length; i++) {
            _totalSlots.increment();
            TimeSlotStruct memory slot;

            slot.id = _totalSlots.current();
            slot.movieId = movieId;
            slot.ticketCost = ticketCosts[i];
            slot.startTime = startTimes[i];
            slot.endTime = endTimes[i];
            slot.day = viewingDays[i];
            slot.capacity = capacities[i];

            movieTimeSlot[slot.id] = slot;
        }
    }

    /**
     * @dev Deletes a time slot for a movie
     * @param movieId The ID of the movie
     * @param slotId The ID of the time slot
     */
    function deleteTimeSlot(uint256 movieId, uint256 slotId) public onlyOwner {
        require(
            movieExists[movieId] && movieTimeSlot[slotId].movieId == movieId,
            "Movie not found"
        );
        require(!movieTimeSlot[slotId].deleted, "Timeslot already deleted");

        for (uint i = 0; i < ticketHolder[movieId][slotId].length; i++) {
            payTo(
                ticketHolder[movieId][slotId][i],
                movieTimeSlot[slotId].ticketCost
            );
        }

        movieTimeSlot[slotId].deleted = true;

        movieTimeSlot[slotId].balance -=
            movieTimeSlot[slotId].ticketCost *
            ticketHolder[movieId][slotId].length;

        delete ticketHolder[movieId][slotId];
    }

    /**
     * @dev Marks a time slot as completed
     * @param movieId The ID of the movie
     * @param slotId The ID of the time slot
     */
    function markTimeSlot(uint256 movieId, uint256 slotId) public onlyOwner {
        require(
            movieExists[movieId] && movieTimeSlot[slotId].movieId == movieId,
            "Movie not found"
        );
        require(!movieTimeSlot[slotId].deleted, "Timeslot already deleted");

        movieTimeSlot[slotId].completed = true;
        balance += movieTimeSlot[slotId].balance;
        movieTimeSlot[slotId].balance = 0;
    }

    /**
     * @dev Returns an array of movie time slots for a given day.
     * @param day The day for which to retrieve the time slots.
     * @return MovieSlots An array of TimeSlotStruct representing the available movie time slots.
     */
    function getTimeSlotsByDay(
        uint256 day
    ) public view returns (TimeSlotStruct[] memory MovieSlots) {
        uint256 available;
        for (uint i = 0; i < _totalSlots.current(); i++) {
            if (
                movieTimeSlot[i + 1].day == day && !movieTimeSlot[i + 1].deleted
            ) {
                available++;
            }
        }

        MovieSlots = new TimeSlotStruct[](available);

        uint256 index;
        for (uint i = 0; i < _totalSlots.current(); i++) {
            if (
                movieTimeSlot[i + 1].day == day && !movieTimeSlot[i + 1].deleted
            ) {
                MovieSlots[index].startTime = movieTimeSlot[i + 1].startTime;
                MovieSlots[index++].endTime = movieTimeSlot[i + 1].endTime;
            }
        }
    }

    /**
     * @dev Returns the details of a specific movie time slot.
     * @param slotId The ID of the movie time slot to retrieve.
     * @return TimeSlotStruct The TimeSlotStruct representing the details of the movie time slot.
     */
    function getTimeSlot(
        uint256 slotId
    ) public view returns (TimeSlotStruct memory) {
        return movieTimeSlot[slotId];
    }

    /**
     * @dev Returns an array of movie time slots for a given movie ID.
     * @param movieId The ID of the movie for which to retrieve the time slots.
     * @return MovieSlots An array of TimeSlotStruct representing the available movie time slots.
     */
    function getTimeSlots(
        uint256 movieId
    ) public view returns (TimeSlotStruct[] memory MovieSlots) {
        uint256 available;
        for (uint i = 0; i < _totalSlots.current(); i++) {
            if (
                movieTimeSlot[i + 1].movieId == movieId &&
                !movieTimeSlot[i + 1].deleted
            ) {
                available++;
            }
        }

        MovieSlots = new TimeSlotStruct[](available);

        uint256 index;
        for (uint i = 0; i < _totalSlots.current(); i++) {
            if (
                movieTimeSlot[i + 1].movieId == movieId &&
                !movieTimeSlot[i + 1].deleted
            ) {
                MovieSlots[index++] = movieTimeSlot[i + 1];
            }
        }
    }

    /**
     * @dev Allows the user to buy movie tickets for a specific movie time slot.
     * @param movieId The ID of the movie for which the ticket is being purchased.
     * @param slotId The ID of the movie time slot for which the ticket is being purchased.
     * @param tickets The number of tickets to purchase.
     */
    function buyTicket(
        uint256 movieId,
        uint256 slotId,
        uint256 tickets
    ) public payable {
        require(
            movieExists[movieId] && movieTimeSlot[slotId].movieId == movieId,
            "Movie not found"
        );
        require(
            msg.value >= movieTimeSlot[slotId].ticketCost * tickets,
            "Insufficient amount"
        );
        require(
            movieTimeSlot[slotId].capacity > movieTimeSlot[slotId].seats,
            "Out of capacity"
        );

        for (uint i = 0; i < tickets; i++) {
            _totalTickets.increment();
            TicketStruct memory ticket;

            ticket.id = _totalTickets.current();
            ticket.cost = movieTimeSlot[slotId].ticketCost;
            ticket.day = movieTimeSlot[slotId].day;
            ticket.slotId = slotId;
            ticket.owner = msg.sender;
            ticket.timestamp = currentTime();

            ticketHolder[movieId][slotId].push(msg.sender);
        }

        movieTimeSlot[slotId].seats += tickets;
        movieTimeSlot[slotId].balance +=
            movieTimeSlot[slotId].ticketCost *
            tickets;
    }

    function getMovieTicketHolders(
        uint256 movieId,
        uint256 slotId
    ) public view returns (address[] memory) {
        return ticketHolder[movieId][slotId];
    }

    function withdrawTo(address to, uint256 amount) public onlyOwner {
        require(balance >= amount, "Insufficient fund");
        balance -= amount;
        payTo(to, amount);
    }

    /**
     * @dev Internal function to transfer funds to a given address.
     * @param to The address to which the funds will be transferred.
     * @param amount The amount of funds to transfer.
     */
    function payTo(address to, uint256 amount) internal {
        (bool success, ) = payable(to).call{value: amount}("");
        require(success);
    }

    /**
     * @dev Internal function to get the current timestamp.
     * @return The current timestamp in milliseconds.
     */
    function currentTime() internal view returns (uint256) {
        uint256 newNum = (block.timestamp * 1000) + 1000;
        return newNum;
    }
}
